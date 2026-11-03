#!/usr/bin/env python3
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from harness_io import results_dir

commands = [[sys.executable, str(ROOT / 'tools/umbrals.py'), 'validate'],
            [sys.executable, str(ROOT / 'tests/catalog_authoring_test.py')]]
results = [subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True) for cmd in commands]
report = {'suite': 'catalog_authoring', 'checks': len(results),
          'failed': sum(result.returncode != 0 for result in results)}
for result in results:
    if result.returncode:
        print(result.stdout + result.stderr, file=sys.stderr)
(results_dir() / 'catalog-authoring-report.json').write_text(json.dumps(report) + '\n')
print(json.dumps(report))
sys.exit(bool(report['failed']))
