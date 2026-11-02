"""Focused menu/save-connection checks; no battle simulations or mutation suite."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'test-results/title-scoped'
OUT.mkdir(parents=True, exist_ok=True)
reports = []
for script in ('asset_catalog_test.gd', 'title_menu_test.gd', 'gold_ui_test.gd', 'codex_navigation_test.gd', 'codex_story_test.gd', 'settings_menu_test.gd', 'startup_smoke.gd'):
    with tempfile.TemporaryDirectory(prefix='umbral-title-check-') as temporary:
        env = dict(os.environ, XDG_DATA_HOME=temporary + '/data',
                   XDG_CONFIG_HOME=temporary + '/config', XDG_CACHE_HOME=temporary + '/cache')
        try:
            result = subprocess.run(['godot', '--headless', '--path', str(ROOT), '--script', 'tests/' + script],
                                    env=env, capture_output=True, text=True, timeout=45)
        except subprocess.TimeoutExpired as error:
            output = (error.stdout or b'').decode() + (error.stderr or b'').decode()
            (OUT / (script + '.timeout.log')).write_text(output)
            raise RuntimeError(f'{script} timed out\n{output}') from error
        output = result.stdout + result.stderr
        (OUT / (script + '.log')).write_text(output)
        if result.returncode or any(s in output for s in ('SCRIPT ERROR:', 'ERROR:', 'instances leaked')):
            raise RuntimeError(f'{script} failed\n{output}')
        records = [json.loads(line) for line in output.splitlines() if line.startswith('{')]
        report = next(item for item in records if 'suite' in item)
        assert report['checks'] > 0 and report['failed'] == 0, report
        reports.append(report)
report = {'suite': 'title_scoped_checks', 'checks': sum(s['checks'] for s in reports),
          'failed': 0, 'suites': reports, 'scope': 'Asset consumer, title presentation/audio, journey/new/cancel/continue, scene startup. No combat simulation.'}
(OUT / 'report.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report))
