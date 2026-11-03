"""Run the current asset pipeline contracts with isolated task output."""
import json
import unittest
from harness_io import ROOT, results_dir
suite = unittest.defaultTestLoader.discover(str(ROOT / 'tests'), pattern='test_asset_pipeline.py')
result = unittest.TextTestRunner(verbosity=2).run(suite)
report = {'suite': 'asset_units', 'checks': result.testsRun, 'failed': len(result.failures) + len(result.errors)}
(results_dir() / 'asset-unit-report.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report))
raise SystemExit(0 if result.wasSuccessful() and result.testsRun > 0 else 1)
