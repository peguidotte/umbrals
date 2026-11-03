"""One executed task graph produces legacy review/CI summaries without shared result folders."""
import json
from pathlib import Path
import re
import shutil
from .manifest import ROOT
from .registry import NATIVE, SCENARIOS
from .runner import atomic_json


def summarize(run):
    out = Path(run['directory'])
    result = dict(run)
    result.update(label=run['options'].get('label', 'harness'),
                  goal=run['options'].get('goal', 'Verificar o alvo declarado no registro do harness.'),
                  version=re.search(r'config/version="([^"]+)"', (ROOT / 'project.godot').read_text()).group(1),
                  evidence_dir=str(out.relative_to(ROOT)) if out.is_relative_to(ROOT) else str(out),
                  harness_report=str(out / 'harness-run.json'), comparisons=[],
                  visual_review='pending; inspect captures/video and record concrete notes',
                  limits=['Local execution; no remote CI claim.', 'Software WebGL is not hardware performance.', 'Focused success does not waive full acceptance.'])
    tasks = run['tasks']
    for key, task in [('architecture', 'architecture'), ('assets', 'assets'), ('content', 'content'), ('authoring', 'authoring'), ('mutations', 'mutations'), ('rules', 'rules'), ('packed_catalog', 'packed-catalog'), ('fixtures', 'fixtures'), ('harness_checks', 'harness'), ('asset_units', 'asset-unit')]:
        if task in tasks and tasks[task].get('report'):
            result[key] = tasks[task]['report']
    suites = [tasks[name]['report'] for name in NATIVE if name != 'rules' and name in tasks and tasks[name].get('report')]
    result['ui'] = {'suite': 'ui_checks', 'checks': sum(report['checks'] for report in suites),
                    'failed': sum(report['failed'] for report in suites), 'suites': suites}
    result['steps'] = [{'name': name, 'status': record['status'], 'exit_code': 0 if record['status'] in ('passed', 'cached') else 130 if record['status'] == 'interrupted' else 1,
                        'seconds': record.get('seconds', 0), 'command': record.get('command', []), 'error': record.get('error')}
                       for name, record in tasks.items()]
    failed = [record for record in tasks.values() if record['status'] in ('failed', 'interrupted')]
    if failed and not result.get('failure'):
        result['failure'] = failed[0].get('error', failed[0]['name'])
    browser = {'suite': 'umbral_ui_experience', 'checks': 0, 'failed': 0, 'captures': [], 'matrix': [],
               'matrix_requested': False, 'matrix_executed': False, 'scenarios': [], 'outcome': 'focused'}
    for name in SCENARIOS:
        task = tasks.get('browser.' + name, {})
        if not task.get('report'): continue
        report = task['report']
        browser['checks'] += report['checks']
        browser['failed'] += report['failed']
        browser['scenarios'].append({'name': name, 'status': task['status'], 'checks': report['checks'], 'seconds': report['seconds']})
        destination = out / 'browser' / name
        if not destination.exists(): shutil.copytree(task['directory'], destination)
        for capture in report['captures']:
            current = dict(capture, file=name + '/' + capture['file'])
            if name not in ('integration', 'layout'): current['name'] = name + '-' + current['name']
            browser['captures'].append(current)
        if name == 'integration' and report['failed'] == 0:
            browser['outcome'] = 'victory'
            video = Path(task['directory']) / 'gameplay.webm'
            if video.exists(): shutil.copy2(video, out / 'browser/gameplay.webm')
        if name == 'layout':
            browser.update(matrix=report['matrix'], matrix_requested=True, matrix_executed=report['matrix_executed'])
        if report.get('failure'): browser['failure'] = report['failure']
    result['browser'] = browser
    if tasks.get('gallery', {}).get('report'):
        result['style_gallery'] = tasks['gallery']['report']
        if not (out / 'style-gallery').exists(): shutil.copytree(tasks['gallery']['directory'], out / 'style-gallery')
    for name in ('ux-contracts.json', 'art-direction-v0.4.md'):
        shutil.copy2(ROOT / 'docs' / name, out / name)
    atomic_json(out / 'run.json', result)
    return result
