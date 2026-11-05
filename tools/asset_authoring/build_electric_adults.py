"""Prepare reviewed adult bodies, drawn resting poses and anatomical motion.

Deterministic alpha/canvas preparation only; original generated images retained.
The art and tuning remain candidates for independent human review.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import shutil
import subprocess

from PIL import Image, ImageOps
from build_electric_family import CHANNELS, PARTS, cast, life, pulse

ROOT = Path(__file__).resolve().parents[2]
RELEASE = ROOT / 'assets/characters/electric-adults/versions/2.0.0'


def write(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')) + '\n')


def state(id, index, t):
    p = life(index, t, True)
    wave = math.sin(t * math.tau / 3.2)
    if id == 'auravel':
        # Wings articulate around their shoulders; no whole-body idle float.
        p[15], p[16] = .028 * wave, -.021 * wave
        if index == 1:
            e = pulse(t, 0, .65, 2.6)
            p[15], p[16] = -.12 * e, .08 * e
        elif index == 6:
            stride = math.sin(t * math.tau / .8)
            p[15], p[16] = .035 * stride, -.025 * stride
    else:
        if index == 6:
            stride = math.sin(t * math.tau / .8)
            p[11], p[16], p[10], p[17] = .13 * stride, -.13 * stride, -.08 * stride, .08 * stride
            p[5] = -.8 * abs(stride)
        else:
            p[10], p[17] = .018 * wave, -.014 * wave
    return [round(v, 6) for v in p]


def attack(id, spec, t):
    p = cast(spec, t, True)
    e = pulse(t, spec['release'] - .15, spec['contact'], 2.5)
    if id == 'auravel':
        p[15], p[16] = -.17 * e, .12 * e
        if spec['index'] >= 12:
            p[11] *= .6
            p[10] *= .6
    else:
        p[16], p[17] = -p[11], -p[10] * .7
    return [round(v, 6) for v in p]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ko-source', type=Path, required=True)
    args = parser.parse_args()
    relative = (RELEASE / 'manifest.json').relative_to(ROOT).as_posix()
    if subprocess.run(['git', 'cat-file', '-e', 'origin/main:' + relative], cwd=ROOT, capture_output=True).returncode == 0:
        raise SystemExit('Published version is immutable; choose a new version')
    RELEASE.mkdir(parents=True, exist_ok=True)
    review = RELEASE / 'review'
    review.mkdir(exist_ok=True)
    (review / '.gdignore').touch()
    prototype = RELEASE.parent / '1.0.0'
    for file in prototype.glob('*.png'):
        shutil.copy2(file, RELEASE / file.name)
    shutil.copy2(prototype / 'review/generated-source.png', review / 'generated-source.png')
    shutil.copy2(ROOT / 'assets/characters/electric-family/versions/2.0.0/review/approved-reference.png', review / 'approved-reference.png')
    shutil.copy2(args.ko_source, review / 'ko-source.png')
    ko = Image.open(args.ko_source).convert('RGBA')
    if ko.size != (1536, 1024):
        raise SystemExit('Expected reviewed 1536x1024 source')
    specs = json.loads((ROOT / 'assets/attacks/woodland-elements/versions/1.1.0/performances.json').read_text())
    specs['parts'] = PARTS
    write(RELEASE / 'performances.json', specs)
    presentation, forms = {}, {}
    for row, id in enumerate(['auravel', 'zuldar']):
        sides = {}
        for column, side in enumerate(['ally', 'enemy']):
            image = ko.crop((column * 768, 0 if row == 0 else 470, (column + 1) * 768, 470 if row == 0 else 1024))
            alpha = image.getchannel('A').point(lambda value: 255 if value >= 192 else 0)
            image.putalpha(alpha)
            image = image.crop(alpha.getbbox())
            if column:
                image = ImageOps.mirror(image)
            image.thumbnail((480, 305 if row == 0 else 300), Image.Resampling.NEAREST)
            out = Image.new('RGBA', (512, 384))
            out.alpha_composite(image, ((512 - image.width) // 2, 360 - image.height))
            out.save(RELEASE / f'{id}-ko-{side}.png')
            sides[side] = dict(texture=f'{id}-{side}', ko_texture=f'{id}-ko-{side}', ko_tint=[.9, .93, .98, 1],
                               foot=[256, 359], display_width=250 if row == 0 else 188, width=390 if row == 0 else 300, visible_top=15, display_height=150 if row == 0 else 146)
        presentation[id] = sides
        if id == 'auravel':
            anatomy = dict(mouth=[.94,.47], eye=[.87,.44],fore=[.69,.88],hind=[.40,.87],quills=[.54,.55],crest=[.74,.37],shoulder=[.71,.65],flank=[.52,.73],secondary=[.26,.41],root=[.58,.91],rump=[.39,.73],chest=[.79,.66])
            joints = dict(head=[.77,.65,.86,.48,.17,.20],fore=[.68,.75,.68,.89,.12,.17],hind=[.47,.73,.40,.87,.13,.18],crest=[.70,.63,.72,.45,.18,.23],wing=[.71,.69,.35,.39,.39,.44],wing_far=[.79,.59,.78,.27,.23,.28])
            feet = [(200,347,0),(273,344,.5),(344,350,.5),(424,346,0)]
            parts = PARTS.copy()
            parts[9:12] = ['secondary','crest','fore']
        else:
            anatomy = dict(mouth=[.74,.30],eye=[.67,.24],fore=[.62,.49],hind=[.40,.88],quills=[.32,.26],crest=[.55,.14],shoulder=[.55,.43],flank=[.48,.62],secondary=[.24,.40],root=[.58,.90],rump=[.39,.67],chest=[.63,.39])
            joints = dict(head=[.62,.38,.65,.25,.19,.22],fore=[.57,.43,.60,.51,.14,.13],arm_far=[.72,.40,.77,.49,.12,.14],hind=[.48,.66,.40,.85,.15,.22],leg_far=[.64,.66,.73,.85,.15,.22],crest=[.53,.38,.36,.32,.30,.34])
            feet = [(210,346,0),(389,346,.5)]
            parts = PARTS
        anatomy['family'] = 'volt'
        forms[id] = dict(anatomy=anatomy,parts=parts,ground=[.5,359/384],profile=dict(mass=1.7 if row == 0 else 2.0),joints=joints,
            walk_contacts=[[x/512,y/384,phase] for x,y,phase in feet],
            states={str(s):[state(id,s,f/30) for f in range(97)] for s in range(8)},
            attacks={str(i):[attack(id,specs['specs'][i],f/30) for f in range(97)] for i in range(15)},
            reactions={str(i):[life(3,f/30,True) for f in range(61)] for i in range(15)})
    write(RELEASE / 'presentation.json', dict(schema=1,forms=presentation))
    write(RELEASE / 'motion.json', dict(schema=1,fps=30,channels=CHANNELS,forms=forms))
    files = {}
    for path in sorted(RELEASE.rglob('*')):
        if not path.is_file() or path.name in ['manifest.json','.gdignore'] or path.suffix in ['.uid','.import']:
            continue
        rel = path.relative_to(RELEASE).as_posix()
        role = path.stem if path.parent == RELEASE else 'source-' + path.stem
        kind = 'review' if rel.startswith('review/') else 'texture' if path.suffix == '.png' else 'data'
        files[role] = dict(path=rel,kind=kind,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),bytes=path.stat().st_size)
        if path.suffix == '.png':
            with Image.open(path) as im:
                files[role]['technical'] = dict(dimensions=list(im.size),mode=im.mode,frames=1,alpha='A' in im.getbands())
    manifest = dict(schema_version=1,id='characters/electric-adults',version='2.0.0',status='production',
        description='Auravel winged quadruped and Zuldar biped: directional actors, anatomical motion and drawn KO/recovery candidates.',
        dependencies=[dict(id='characters/electric-family',version='2.1.0')],files=files,
        provenance=dict(kind='Original Image Gen referenced to approved electric family; original images and metadata retained.',
            reference_library_file_id='libfile_2b00aa3086e48191af8247acac969990',
            reference_sha256=hashlib.sha256((review / 'approved-reference.png').read_bytes()).hexdigest(),
            normalization='Fixed alpha >=192, crop, nearest fit, 512x384 canvas; opposite view canonicalized before runtime mirror.',
            motion='Own wing and biped joints, explicit support contacts, original curves with shared attack event clocks.',
            limits='Review candidates; KO uses closed-eye drawn poses with crossfade. Auravel resting wings remain raised. No claim of final hand-drawn animation or final balance.',
            license='Original project generated artwork and authored motion.'))
    (RELEASE / 'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    print('Prepared electric-adults@2.0.0; validate pins and actual-scale captures.')


if __name__ == '__main__':
    main()
