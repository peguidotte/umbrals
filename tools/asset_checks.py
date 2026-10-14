"""Validate shipped source provenance, PNG constraints and actual PCM samples."""
from array import array
import hashlib
import json
from pathlib import Path
import sys
import wave

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / 'assets/asset-manifest.json').read_text())
listed = {item['path'] for item in manifest['assets']}
actual = {str(path.relative_to(ROOT)) for path in (ROOT / 'assets').rglob('*') if path.suffix in {'.svg','.png','.wav','.ttf'}}
if actual != listed:
    raise RuntimeError(f'Provenance coverage differs: {actual ^ listed}')
audio = []
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
report={'suite':'asset_qa','source_assets':len(listed),'failed':0,'audio':audio,'limits':'PCM checks do not replace hearing the audio on hardware; hashes do not decide aesthetics or license rights.'}
(ROOT / 'test-results/asset-report.json').write_text(json.dumps(report,indent=2))
print(json.dumps({'suite':report['suite'],'source_assets':report['source_assets'],'failed':0}))
