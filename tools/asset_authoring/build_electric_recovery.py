"""Rebuild the unpublished electric pose release from byte-exact source images."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ko-source', type=Path, required=True)
    args = parser.parse_args()
    old = ROOT / 'assets/characters/electric-family/versions/1.0.0'
    new = old.parent / '2.0.0'
    relative = (new / 'manifest.json').relative_to(ROOT).as_posix()
    if subprocess.run(['git', 'cat-file', '-e', 'origin/main:' + relative], cwd=ROOT, capture_output=True).returncode == 0:
        raise SystemExit('Published release is immutable; choose a new version')
    shutil.copytree(old, new, ignore=shutil.ignore_patterns('*.import', '*.uid'), dirs_exist_ok=True)
    shutil.copy2(args.ko_source, new / 'review/ko-source.png')
    source = Image.open(args.ko_source).convert('RGBA')
    if source.size != (1536, 1024):
        raise SystemExit('Expected the reviewed 1536x1024 four-pose source')
    presentation = json.loads((new / 'presentation.json').read_text())
    for name, id, y1, y2 in [('nisca', 'volt', 0, 480), ('niscor', 'tempestral', 480, 1024)]:
        for column, side in enumerate(['ally', 'enemy']):
            image = source.crop((column * 768, y1, (column + 1) * 768, y2))
            alpha = image.getchannel('A').point(lambda value: 255 if value >= 192 else 0)
            image.putalpha(alpha)
            image = image.crop(alpha.getbbox())
            if column:
                image = ImageOps.mirror(image)
            image.thumbnail((350, 250), Image.Resampling.NEAREST)
            output = Image.new('RGBA', (384, 320))
            output.alpha_composite(image, ((384 - image.width) // 2, 300 - image.height))
            output.save(new / (name + '-ko-' + side + '.png'))
            presentation['forms'][id][side].update(ko_texture=name + '-ko-' + side, ko_tint=[.86, .9, .95, 1])
    (new / 'presentation.json').write_text(json.dumps(presentation, separators=(',', ':')) + '\n')
    motion = json.loads((new / 'motion.json').read_text())
    feet = {'volt': [(108, 292, 0), (167, 284, .5), (240, 296, .5), (319, 291, 0)],
            'tempestral': [(82, 296, 0), (160, 290, .5), (240, 297, .5), (306, 295, 0)]}
    for id, points in feet.items():
        motion['forms'][id]['walk_contacts'] = [[x / 384, y / 320, phase] for x, y, phase in points]
    (new / 'motion.json').write_text(json.dumps(motion, separators=(',', ':')) + '\n')
    manifest = json.loads((old / 'manifest.json').read_text())
    manifest.update(version='2.0.0',
        changes='Add authored closed-eye KO poses, stance contacts and transition/recovery roles. Requires the pose-aware consumer.',
        description='Nisca/Niscor directional sprites and motion candidates revised after independent review; human acceptance pending.')
    manifest['provenance'].update(
        review='No claim of final animation quality; verify actual cadence, stance and recovery in native/Web captures.',
        ko_source='Image Gen exec-3c223150-ef0d-45bd-a3f7-520b20e28809; original preserved.',
        walk='Four explicit support points; 60% planted stance, 40% swing; normalized coordinates from visible gold paws.')
    for path in new.rglob('*'):
        if not path.is_file() or path.name in ['manifest.json', '.gdignore'] or path.suffix in ['.uid', '.import']:
            continue
        rel = path.relative_to(new).as_posix()
        role = path.stem if path.parent == new else 'source-' + path.stem
        manifest['files'][role] = {'path': rel, 'kind': 'review' if rel.startswith('review/') else 'texture' if path.suffix == '.png' else 'data',
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'bytes': path.stat().st_size}
    (new / 'manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n')
    print('Rebuilt electric-family@2.0.0; refresh, build and validate before proposing pins.')


if __name__ == '__main__':
    main()
