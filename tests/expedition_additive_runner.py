#!/usr/bin/env python3
"""Run and account for every isolated additive migration scenario."""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from harness_io import results_dir

result = subprocess.run([sys.executable, str(ROOT / 'tests/expedition_additive_test.py')], cwd=ROOT,
                        capture_output=True, text=True, timeout=240)
output = result.stdout + result.stderr
print(output, end='')
positive = re.findall(r'(?m)^Additive integration failures: (\d+)\s*$', output)
negative = re.findall(r'(?m)^Incompatible integration failures: (\d+)\s*$', output)
complete = (result.returncode == 0 and positive == ['0'] and negative == ['0'] * 4
            and 'SCRIPT ERROR:' not in output and '\nERROR:' not in output)
report = {'suite': 'migration_compat', 'checks': len(positive) + len(negative),
          'failed': 0 if complete else 1}
(results_dir() / 'migration-compat-report.json').write_text(json.dumps(report) + '\n')
print(json.dumps(report))
sys.exit(0 if complete else 1)
