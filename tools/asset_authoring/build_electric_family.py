"""Normalize generated sprites and author hedgehog motion, without editing old releases.

Source images remain byte-exact under review/. Inputs must be materialized by
the Library workflow; this script performs only deterministic asset preparation.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import shutil
import subprocess

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[2]
RELEASE = ROOT / 'assets/characters/electric-family/versions/1.0.0'
CHANNELS = ['x', 'y', 'rotation', 'sx', 'sy', 'bob', 'inflate', 'blink',
            'head', 'tail', 'fore', 'hind', 'crest', 'ear', 'jaw', 'wing',
            'feeler', 'bough', 'fin', 'reach']
PARTS = ['mouth', 'rump', 'fore', 'fore', 'root', 'crest', 'mouth', 'chest',
         'hind', 'quills', 'crest', 'fore', 'shoulder', 'quills', 'flank']


def write(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')) + '\n')


def rest():
    return [0., 0., 0., 1., 1.] + [0.] * 15


def smooth(value):
    x = max(0., min(1., value))
    return x * x * (3 - 2 * x)


def pulse(t, start, peak, end):
    return smooth((t - start) / (peak - start)) if t <= peak else 1 - smooth((t - peak) / (end - peak))


def life(state, t, adult):
    p = rest()
    wave = math.sin(t * math.tau / 3.2)
    if state == 0:
        # Breath moves the torso, never the floor pivot or whole-body scale.
        p[6], p[8], p[13] = .012 * wave, .018 * wave, .025 * wave
        p[7] = pulse(t, 2.35, 2.43, 2.55)
    elif state == 1:
        e = pulse(t, 0, .65, 2.6)
        p[6], p[12], p[8] = .05 * e, -.08 * e, -.04 * e
    elif state == 2:
        p[8], p[13] = .07 * wave, .1 * wave
    elif state == 3:
        e = pulse(t, 0, .12, .75)
        p[0], p[2], p[4], p[8] = -11 * e, -.08 * e, 1 - .09 * e, -.15 * e
    elif state == 4:
        e = pulse(t, 0, .5, 2.6)
        p[4], p[6], p[12], p[8] = 1 - .09 * e, .07 * e, -.1 * e, -.08 * e
    elif state == 5:
        e = pulse(t, 0, .6, 2.6)
        p[8], p[13], p[6] = -.06 * e, -.09 * e, .025 * e
    elif state == 6:
        # In-place four-legged gait; separate hind/fore joints, not a renamed dash.
        stride = math.sin(t * math.tau / .8)
        p[10], p[11], p[8] = .17 * stride, -.14 * stride, .022 * stride
        p[5] = -1.1 * abs(stride)
    elif state == 7:
        e = smooth(t / .65)
        p[0], p[2], p[4], p[8], p[7] = -5 * e, -.13 * e, 1 - .36 * e, .18 * e, e
    if adult:
        p[6] *= .8
        p[10] *= .85
    return [round(x, 6) for x in p]


def cast(spec, t, adult):
    p = rest()
    anticipation = pulse(t, spec['start'], spec['release'] - .08, spec['release'] + .2)
    strike = pulse(t, spec['release'] - .12, spec['contact'], 2.5)
    p[0], p[8], p[12], p[6] = -5 * anticipation, -.07 * anticipation + .08 * strike, -.07 * anticipation, .04 * anticipation
    index = spec['index']
    if index % 3 == 2:
        p[10] = -.22 * anticipation + .13 * strike
    if index >= 12:
        reach = pulse(t, spec['release'] - .18, spec['contact'], 2.55)
        p[19] = reach
        p[0] += 300 * reach  # runtime replaces exactly this component with slot dash
        p[10] = .18 * math.sin(t * math.tau / .32) * strike
        p[11] = -p[10] * .8
        if index == 13:
            p[1], p[2] = -90 * strike, -.18 * anticipation + .16 * strike
        elif index == 14:
            p[2], p[4] = -.3 * strike, 1 - .14 * strike
        else:
            p[2] = .08 * strike
    if adult:
        p[8] *= .8
    return [round(x, 6) for x in p]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--reference', type=Path, required=True)
    args = parser.parse_args()
    if subprocess.run(['git', 'cat-file', '-e', 'origin/main:' + str((RELEASE / 'manifest.json').relative_to(ROOT))], cwd=ROOT, capture_output=True).returncode == 0:
        raise SystemExit('Release already published: create a new version')
    RELEASE.mkdir(parents=True, exist_ok=True)
    review = RELEASE / 'review'
    review.mkdir(exist_ok=True)
    (review / '.gdignore').touch()
    shutil.copy2(args.source, review / 'generated-source.png')
    shutil.copy2(args.reference, review / 'approved-reference.png')
    source = Image.open(args.source).convert('RGBA')
    if source.size != (1536, 1024):
        raise SystemExit('Expected reviewed 1536x1024 four-cell source')
    forms, presentation = {}, {}
    specs = json.loads((ROOT / 'assets/attacks/woodland-elements/versions/1.1.0/performances.json').read_text())
    specs['parts'] = PARTS
    write(RELEASE / 'performances.json', specs)
    for row, (id, name) in enumerate([('volt', 'nisca'), ('tempestral', 'niscor')]):
        sides = {}
        for column, side in enumerate(['ally', 'enemy']):
            y1, y2 = (0, 445) if row == 0 else (445, 1024)
            im = source.crop((column * 768, y1, (column + 1) * 768, y2))
            # Remove the generated diffuse halo using a fixed alpha threshold.
            # No background color keying: cream muzzle and gold quills are retained.
            alpha = im.getchannel('A').point(lambda v: 255 if v >= 192 else 0)
            im.putalpha(alpha)
            im = im.crop(alpha.getbbox())
            if side == 'enemy':
                # Store a canonical right-facing texture; the runtime mirrors its
                # mesh AND sockets together. Pixels originate from the opposite view.
                im = ImageOps.mirror(im)
            im.thumbnail((350, 280), Image.Resampling.NEAREST)
            out = Image.new('RGBA', (384, 320))
            out.alpha_composite(im, ((384 - im.width) // 2, 300 - im.height))
            out.save(RELEASE / f'{name}-{side}.png')
            sides[side] = {'texture': f'{name}-{side}', 'foot': [192, 299],
                           'width': 250 if row == 0 else 260, 'visible_top': 20,
                           'display_height': 104 if row == 0 else 134}
        # Coordinates are authored against the normalized right-facing images.
        anatomy = ({'mouth': [.82, .74], 'eye': [.72, .60], 'fore': [.63, .89],
                    'hind': [.27, .88], 'quills': [.75, .32], 'crest': [.49, .24],
                    'shoulder': [.60, .70], 'flank': [.44, .70], 'secondary': [.58, .22]}
                   if row == 0 else
                   {'mouth': [.84, .48], 'eye': [.76, .41], 'fore': [.63, .86],
                    'hind': [.26, .86], 'quills': [.65, .23], 'crest': [.46, .18],
                    'shoulder': [.65, .61], 'flank': [.46, .60], 'secondary': [.51, .12]})
        anatomy.update(family='volt', root=[.45, .84], rump=[.25, .7], chest=[.7, .66])
        head = [.65, .62, .72, .60, .24, .26] if row == 0 else [.68, .50, .76, .43, .2, .2]
        forms[id] = {'anatomy': anatomy, 'parts': PARTS, 'ground': [.5, 299 / 320],
            'profile': {'mass': .7 if row == 0 else 1.25},
            'joints': {'head': head, 'fore': [.60, .76, .65, .89, .15, .17],
                       'hind': [.32, .75, .27, .88, .16, .17],
                       'crest': [.47, .65, .43, .38, .38, .4],
                       'ear': [.61, .51, .58, .47, .12, .12]},
            'states': {str(s): [life(s, f / 30, row == 1) for f in range(97)] for s in range(8)},
            'attacks': {str(i): [cast(specs['specs'][i], f / 30, row == 1) for f in range(97)] for i in range(15)},
            'reactions': {str(i): [life(3, f / 30, row == 1) for f in range(61)] for i in range(15)}}
        presentation[id] = sides
    write(RELEASE / 'motion.json', {'schema': 1, 'fps': 30, 'channels': CHANNELS, 'forms': forms})
    write(RELEASE / 'presentation.json', {'schema': 1, 'forms': presentation})
    provenance = {'kind': 'Image Gen production candidate, referenced to user-approved electric family; original PNGs retained.',
        'reference_library_file_id': 'libfile_2b00aa3086e48191af8247acac969990',
        'reference_sha256': hashlib.sha256(args.reference.read_bytes()).hexdigest(),
        'normalization': 'Fixed alpha >=192, component crop, nearest fit, 384x320 canvas, baseline y=299; opposite-view pixels canonicalized before mesh mirror.',
        'motion': 'Original hedgehog anatomical curves; shared event clocks only. Not the prior beetle tracks.',
        'license': 'Original project generated artwork and authored motion; no external game assets.',
        'review': 'Technical integration candidate in draft branch; final human art review pending.'}
    files = {}
    for path in sorted(RELEASE.rglob('*')):
        if not path.is_file() or path.name in ['manifest.json', '.gdignore']:
            continue
        rel = path.relative_to(RELEASE).as_posix()
        role = path.stem if '/' not in rel else 'source-' + path.stem
        kind = 'review' if rel.startswith('review/') else 'texture' if path.suffix == '.png' else 'data'
        files[role] = {'path': rel, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                       'bytes': path.stat().st_size, 'kind': kind}
        if kind == 'texture':
            files[role]['technical'] = {'dimensions': [384, 320], 'mode': 'RGBA', 'frames': 1, 'alpha': True}
    manifest = {'schema_version': 1, 'id': 'characters/electric-family', 'version': '1.0.0',
        'status': 'production', 'description': 'Nisca and Niscor directional sprites with authored mesh states, gait and anatomical attacks.',
        'dependencies': [], 'provenance': provenance, 'files': files}
    (RELEASE / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    print('Prepared electric-family@1.0.0; runtime pins require explicit integration review.')


if __name__ == '__main__':
    main()
