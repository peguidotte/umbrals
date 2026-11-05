"""Verify untouched sources and real selected pixels; no image rewriting."""
from pathlib import Path
from PIL import Image
import hashlib
import json

ROOT = Path(__file__).resolve().parents[6]
RELEASE = Path(__file__).resolve().parents[1]
manifest = json.loads((RELEASE / 'manifest.json').read_text())
data = json.loads((RELEASE / 'poses.json').read_text())
rows = []
for name, clip in data['clips'].items():
    item = manifest['files'][clip['file']]
    path = RELEASE / item['path']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256']
    image = Image.open(path)
    image.load()
    assert image.mode == 'RGBA'
    alpha = image.getchannel('A')
    assert alpha.getextrema()[0] == 0 and alpha.getextrema()[1] >= 240
    regions = []
    for index, frame in enumerate(clip['frames']):
        x, y, width, height = frame['region']
        assert 0 <= x < x + width <= image.width and 0 <= y < y + height <= image.height
        for a, b, w, h in regions:
            assert not (max(x, a) < min(x + width, a + w) and max(y, b) < min(y + height, b + h))
        regions.append(frame['region'])
        selected = alpha.crop((x, y, x + width, y + height))
        solid = selected.point(lambda z: 255 if z > 64 else 0).getbbox()
        assert solid is not None
        margin = min(solid[0], solid[1], width - solid[2], height - solid[3])
        assert margin >= 1, 'Opaque figure cut at region/texture edge'
        coverage = sum(selected.histogram()[17:]) / (width * height)
        assert .1 < coverage < .85, 'Missing drawing or opaque backdrop'
        floor = None
        if frame.get('floor_contact'):
            # Independent pixel scan verifies that the authored sole metadata
            # actually describes the lowest visible boot pixels.
            assert frame['sole_y'] == solid[3]
            floor = 1450 + frame['bed_offset'][1] + (solid[3] - frame['pivot'][1]) * clip['scale']
            assert abs(floor - 1730) < .01, 'Grounded wake pose floats or sinks'
        rows.append({'clip': name, 'frame': index, 'margin_px': margin,
                     'coverage': round(coverage, 4), 'floor_contact_y': floor})
assert len(rows) == 22
out = ROOT / 'test-results/pietro-transition-source-qa'
out.mkdir(parents=True, exist_ok=True)
report = {'status': 'passed', 'figures': len(rows), 'rows': rows,
          'scope': 'Unmodified source hashes, true alpha, disjoint complete regions and calibrated boot pixels. Not visual approval.'}
(out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
