"""Validate shipped source provenance, PNG constraints and actual PCM samples."""
from array import array
import hashlib
import json
from pathlib import Path
import sys
import wave

from PIL import Image
from asset_pipeline import digest, inside, load_releases, read_json, validate

ROOT = Path(__file__).resolve().parents[1]
module_report = validate(ROOT)
manifest = json.loads((ROOT / 'assets/asset-manifest.json').read_text())
listed = {item['path'] for item in manifest['assets']}
# Complete ownership/coverage (including metadata and review media) is checked by
# the module validator. Retain the original per-file PCM and PNG quality gates.
audio = []
# Audit the original migration independently of the generated inventory.
migration = read_json(ROOT / 'docs/assets/migration-map.json')
if migration['source_asset_count'] != len(migration['files']):
    raise RuntimeError('Incomplete migration audit')
for item in migration['files']:
    if digest(inside(ROOT, item['to'])) != item['sha256']:
        raise RuntimeError(f'Migrated original differs: {item["from"]}')

# Verify actual normalized prototype frames, including page boundaries, against
# the preserved original RGBA PNGs. Byte hashes alone cannot prove this property.
normalized_frames = 0
for _, (manifest_path, release) in load_releases(ROOT).items():
    for animation in release.get('animations', {}).values():
        frame = 0
        for page in animation.get('pages', [animation]):
            record = release['files'][page['file']]
            normalization = record.get('provenance', {}).get('normalization')
            if not normalization:
                frame += page['frames']
                continue
            source = inside(manifest_path.parent, normalization['original_file'])
            if digest(source) != normalization['original_sha256']:
                raise RuntimeError('Normalized atlas original changed')
            w, h = animation['frame_size']
            source_columns, columns = normalization['source_columns'], animation['columns']
            with Image.open(source) as original, Image.open(inside(manifest_path.parent, record['path'])) as packed:
                for index in range(page['frames']):
                    x, y = frame % source_columns * w, frame // source_columns * h
                    px, py = index % columns * w, index // columns * h
                    if original.crop((x,y,x+w,y+h)).tobytes() != packed.crop((px,py,px+w,py+h)).tobytes():
                        raise RuntimeError(f'Normalized frame pixels changed: {manifest_path}:{frame}')
                    normalized_frames += 1
                    frame += 1
for item in manifest['assets']:
    path = ROOT / item['path']
    if hashlib.sha256(path.read_bytes()).hexdigest() != item['sha256']:
        raise RuntimeError(f'Changed asset needs a provenance update: {item["path"]}')
    if not item.get('source'):
        raise RuntimeError(f'Missing source record: {item["path"]}')
    if path.suffix == '.png':
        with Image.open(path) as image:
            if list(image.size) != item['technical']['dimensions'] or image.mode != item['technical']['mode']:
                raise RuntimeError(f'Image constraints changed: {item["path"]}')
    if path.suffix == '.wav':
        with wave.open(str(path)) as sound:
            if sound.getsampwidth()!=2 or sound.getnchannels()!=1 or sound.getframerate()!=22050:
                raise RuntimeError(f'PCM format changed: {item["path"]}')
            samples=array('h',sound.readframes(sound.getnframes()))
            if sys.byteorder != 'little': samples.byteswap()
            if not samples or max(abs(sample) for sample in samples) >= 32767:
                raise RuntimeError(f'Empty or clipped PCM: {item["path"]}')
            audio.append({'path':item['path'],'frames':len(samples),'peak':max(abs(sample) for sample in samples),'clipped_samples':0})
report={'suite':'asset_qa','source_assets':len(listed),'failed':0,'audio':audio,'modules':module_report,'migration_originals_verified':len(migration['files']),'normalized_frames_verified':normalized_frames,'limits':'PCM checks do not replace hearing the audio on hardware; hashes do not decide aesthetics or license rights.'}
(ROOT / 'test-results').mkdir(exist_ok=True)
(ROOT / 'test-results/asset-report.json').write_text(json.dumps(report,indent=2))
print(json.dumps({'suite':report['suite'],'source_assets':report['source_assets'],'failed':0}))
