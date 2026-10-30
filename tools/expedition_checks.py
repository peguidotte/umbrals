"""Run expedition suites with temporary Godot user data and validate their reports."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'test-results'
OUT.mkdir(exist_ok=True)
suites = [
    ('rules', 'tests/expedition_rules_test.gd', r'Expedition checks: (\d+); failures: (\d+)', 51),
    ('save', 'tests/expedition_save_test.gd', r'Expedition save: (\d+) assertions, (\d+) failures', 24),
    ('ui', 'tests/expedition_ui_test.gd', r'Expedition UI: (\d+) assertions, (\d+) failures', 15),
]
report = {'suite':'umbral_expedition', 'checks':0, 'failed':0, 'suites':[]}
with tempfile.TemporaryDirectory(prefix='umbral-expedition-checks-') as temp:
    for name, script, pattern, minimum in suites:
        env = os.environ.copy()
        env['XDG_DATA_HOME'] = str(Path(temp) / name / 'data')
        env['XDG_CONFIG_HOME'] = str(Path(temp) / name / 'config')
        result = subprocess.run(['bash', '-c', 'set -euo pipefail; source tools/environment.sh; godot --headless --path . --script "$1"', 'expedition-check', script], cwd=ROOT, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
        (OUT / f'expedition-{name}.log').write_text(result.stdout)
        match = re.search(pattern, result.stdout)
        count, failures = (int(match.group(1)), int(match.group(2))) if match else (0, 1)
        errors = [line for line in result.stdout.splitlines() if re.search(r'(?:SCRIPT ERROR:|^ERROR:|^FAIL:)', line)]
        ok = result.returncode == 0 and count >= minimum and failures == 0 and not errors
        report['checks'] += count
        report['failed'] += int(not ok)
        report['suites'].append({'name':name, 'checks':count, 'failures':failures, 'exit_code':result.returncode, 'errors':errors, 'status':'passed' if ok else 'failed'})
(OUT / 'expedition-report.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report))
sys.exit(int(report['failed'] != 0))
