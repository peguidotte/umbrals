"""Validate the exact development preview while leaving production pins untouched."""
import json
from card_asset_pipeline import ROOT, snapshot, validate_presentation
from asset_pipeline import AssetError
from harness_io import results_dir

actual = snapshot()
report = validate_presentation(ROOT, ('ui/power-card-system', '0.3.0'), actual, 'development')
try:
    strict = validate_presentation(ROOT, ('ui/power-card-system', '0.3.0'), actual, 'production')
except AssetError as error:
    assert 'unapproved art' in str(error), str(error)
else:
    assert strict['failed'] > 0, 'Incomplete prototype must be refused by the production gate'
assert report['covered'] == 6 and report['approved'] == 0, 'Pilot candidates must never imply approved catalog completion'
report.update({'suite': 'card_preview_assets', 'checks': report['required']})
(results_dir() / 'card-preview-report.json').write_text(json.dumps(report, indent=2))
print(json.dumps({key: report[key] for key in ['suite', 'checks', 'failed', 'covered', 'approved']}))
