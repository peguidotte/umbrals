"""Run UI/input/preferences checks with isolated user data; never overwrite player settings."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
reports = []
for script in ('asset_catalog_test.gd', 'ui_state_test.gd', 'ui_flow_test.gd', 'startup_smoke.gd'):
    with tempfile.TemporaryDirectory(prefix='umbral-ui-test-') as temporary:
        env = dict(os.environ)
        env['XDG_DATA_HOME'] = str(Path(temporary) / 'data')
        env['XDG_CONFIG_HOME'] = str(Path(temporary) / 'config')
        env['XDG_CACHE_HOME'] = str(Path(temporary) / 'cache')
        result = subprocess.run(['godot', '--headless', '--path', str(ROOT), '--script', 'tests/' + script], env=env, capture_output=True, text=True, timeout=45)
        output = result.stdout + result.stderr
        (ROOT / 'test-results' / (script.removesuffix('.gd') + '.log')).write_text(output)
        if result.returncode or 'SCRIPT ERROR:' in output or 'ERROR:' in output or 'instances leaked' in output:
            raise RuntimeError(f'{script} failed\n{output}')
        records = [json.loads(line) for line in output.splitlines() if line.startswith('{')]
        report = next(item for item in records if 'suite' in item)
        assert report['checks'] > 0 and report['failed'] == 0, report
        reports.append(report)
result = {'suite': 'ui_checks', 'checks': sum(item['checks'] for item in reports), 'failed': 0, 'suites': reports}
(ROOT / 'test-results/ui-report.json').write_text(json.dumps(result, indent=2))
print(json.dumps(result))
