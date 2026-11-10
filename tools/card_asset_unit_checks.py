"""Run isolated card presentation contract cases."""
import json
import unittest
from harness_io import ROOT, results_dir
suite = unittest.defaultTestLoader.discover(str(ROOT / 'tests'), pattern='test_card_assets.py')
result = unittest.TextTestRunner(verbosity=2).run(suite)
report = {'suite': 'card_asset_units', 'checks': result.testsRun, 'failed': len(result.failures) + len(result.errors)}
(results_dir() / 'card-asset-unit-report.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report))
raise SystemExit(0 if result.wasSuccessful() and result.testsRun else 1)
