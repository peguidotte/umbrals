"""Enforce layers and prevent new debt while integrating the current product main.
Existing debt is measured against an explicit, reviewed baseline, never silently waived.
"""
from collections import Counter
import json
from pathlib import Path
import re
from harness_io import ROOT, results_dir

ALLOWED = {
    'composition': {'application', 'rules', 'catalog', 'ui', 'storage', 'assets', 'battle', 'expedition', 'domain', 'session', 'platform'},
    'application': {'application', 'session', 'rules', 'ui', 'platform', 'catalog', 'assets', 'battle', 'domain'},
    'rules': {'catalog', 'battle', 'domain'},
    'battle': {'catalog', 'battle', 'domain'},
    'domain': {'catalog', 'battle', 'domain'},
    'catalog': {'catalog', 'domain'},
    'expedition': {'rules', 'catalog', 'battle', 'expedition', 'domain'},
    'ui': {'ui', 'rules', 'catalog', 'battle', 'assets', 'storage', 'expedition', 'domain'},
    'storage': {'storage'},
    'assets': {'assets'},
    'session': {'session', 'rules', 'expedition', 'domain', 'storage', 'catalog'},
    'platform': {'platform', 'ui', 'catalog', 'domain'},
}


def layer(path):
    if path == 'scripts/main.gd': return 'composition'
    if path == 'scripts/rules.gd': return 'rules'
    if path == 'scripts/content.gd': return 'catalog'
    if path == 'scripts/codex_progress.gd': return 'session'
    if path in {'scripts/storage.gd', 'scripts/expedition/run_save.gd'}: return 'storage'
    for name in ('application', 'battle', 'ui', 'assets', 'expedition', 'domain', 'session', 'platform', 'catalog'):
        if path.startswith('scripts/' + name + '/'): return name
    return None


def metrics(path, source):
    code = '\n'.join(line.split(' #', 1)[0] for line in source.splitlines() if not line.lstrip().startswith('#'))
    owner = layer(path)
    result = Counter(lines=sum(bool(line.strip()) for line in code.splitlines()))
    patterns = {
        'global-rng': r'(?<![\w.])(?:randf|randi|randf_range|randi_range|randomize|seed)\s*\(',
        'test-boundary': r'(?:preload\(|load\(|extends\s+)\s*["\']res://tests/',
    }
    if owner in {'rules', 'battle', 'domain', 'catalog', 'expedition'}:
        patterns['pure-domain'] = r'\b(?:FileAccess|DirAccess|JavaScriptBridge|HTTPClient|HTTPRequest|AudioServer|Input|SceneTree|Node|Control)\b|\bget_tree\s*\('
    if owner in {'composition', 'application'}:
        patterns['widget-ownership'] = r'\b(?:Button|Label|TextureRect|VBoxContainer|HBoxContainer|PanelContainer|ColorRect|MarginContainer|HSlider|CheckButton)\.new\('
        patterns['platform-ownership'] = r'\b(?:FileAccess|DirAccess|JavaScriptBridge)\b|create_tween\('
    if owner == 'ui':
        patterns['view-commands'] = r'\bgame\.(?:play|toggle|redraw|choose_reward|new_run|queue_item|queue_swap)\s*\(|\bgame\.\w+\s*(?:=(?!=)|\+=|-=)'
    if owner in {'ui', 'application'}:
        patterns['host-reference'] = r'\b(?:app|host|coordinator|main)\s*[:=]'
    if owner in {'application', 'rules', 'battle', 'domain', 'catalog', 'ui', 'session'}:
        patterns['ordinal-forms'] = r'\.stage\b|var stage\s*:'
    if owner in {'rules', 'battle'}:
        patterns['species-switch'] = r'\b(?:\w+\.)?species\s*==\s*[\"\'][a-z][a-z0-9_]*[\"\']'
    if owner == 'rules':
        patterns['global-catalog'] = r'Content\.(?:SPECIES|POWERS|ENCOUNTERS|STARTING_ITEMS)\b'
        patterns['embedded-planner'] = r'func best_selection\([^\n]*\n(?!\s+return Planner\.choose\()'
        patterns['untyped-runtime'] = r'var (?:party|enemies|hand|deck|discard_pile|reward_offers): Array(?!\[)'
    for name, pattern in patterns.items(): result[name] = len(re.findall(pattern, code))
    return result


def check(sources, baseline):
    errors, debts, graph = [], [], {}
    for path, source in sources.items():
        owner = layer(path)
        if owner is None:
            errors.append({'file': path, 'rule': 'known-layer'})
            continue
        values = metrics(path, source)
        previous = baseline.get('files', {}).get(path, {}).get('metrics', {})
        for name, value in values.items():
            default = (400 if owner == 'composition' else 350) if name == 'lines' else 0
            limit = max(default, previous.get(name, 0))
            if value > limit: errors.append({'file': path, 'rule': name, 'actual': value, 'limit': limit})
            if value > default: debts.append({'file': path, 'rule': name, 'actual': value, 'target': default, 'baseline': previous.get(name, 0)})
        graph[path] = re.findall(r'(?:preload\(|load\(|extends\s+)\s*["\']res://(scripts/[^"\']+)["\']', source)
        for dependency in graph[path]:
            if dependency not in sources: errors.append({'file': path, 'rule': 'missing-dependency', 'dependency': dependency})
            elif layer(dependency) not in ALLOWED[owner]: errors.append({'file': path, 'rule': 'dependency-direction', 'dependency': dependency})
    seen, active = set(), set()
    def visit(path):
        if path in active:
            errors.append({'file': path, 'rule': 'acyclic-dependencies'})
            return
        if path in seen: return
        active.add(path)
        for dependency in graph.get(path, []): visit(dependency)
        active.remove(path)
        seen.add(path)
    for path in graph: visit(path)
    return errors, debts


def negative_checks(sources, baseline):
    sources = dict(sources, **{'scripts/application/layer_probe.gd': 'extends RefCounted'})
    cases = [
        ('view imports application', 'scripts/ui/negative.gd', 'const Bad = preload("res://scripts/application/layer_probe.gd")', 'dependency-direction'),
        ('domain imports application', 'scripts/domain/negative.gd', 'const Bad = preload("res://scripts/application/layer_probe.gd")', 'dependency-direction'),
        ('session imports application', 'scripts/session/negative.gd', 'const Bad = preload("res://scripts/application/layer_probe.gd")', 'dependency-direction'),
        ('application imports main', 'scripts/application/negative.gd', 'const Bad = preload("res://scripts/main.gd")', 'dependency-direction'),
        ('application imports storage', 'scripts/application/negative.gd', 'const Bad = preload("res://scripts/storage.gd")', 'dependency-direction'),
        ('application captures coordinator', 'scripts/application/negative.gd', 'var host: Control', 'host-reference'),
        ('application captures main', 'scripts/application/negative.gd', 'var main: Control', 'host-reference'),
        ('application owns widget', 'scripts/application/negative.gd', 'func bad(): Label.new()', 'widget-ownership'),
        ('application owns platform', 'scripts/application/negative.gd', 'func bad(): FileAccess.open("x", 1)', 'platform-ownership'),
        ('application module grows', 'scripts/application/negative.gd', 'var x = 0\n' * 351, 'lines'),
        ('domain imports UI', 'scripts/battle/negative.gd', 'const Bad = preload("res://scripts/ui/kit.gd")', 'dependency-direction'),
        ('domain uses storage', 'scripts/battle/negative.gd', 'func bad(): FileAccess.open("x", 1)', 'pure-domain'),
        ('ordinal form in view', 'scripts/ui/negative.gd', 'func bad(): return individual.stage', 'ordinal-forms'),
        ('species switch in mechanics', 'scripts/battle/negative.gd', 'func bad(): return individual.species == "ember"', 'species-switch'),
        ('global RNG', 'scripts/battle/negative.gd', 'func bad(): randf()', 'global-rng'),
        ('test enters production', 'scripts/battle/negative.gd', 'const Bad = preload("res://tests/browser/fixture_entry.gd")', 'test-boundary'),
        ('view mutates rules', 'scripts/ui/negative.gd', 'func bad(): game.play()', 'view-commands'),
        ('view captures coordinator', 'scripts/ui/negative.gd', 'var app: Node', 'host-reference'),
        ('new module grows', 'scripts/battle/negative.gd', 'var x = 0\n' * 351, 'lines'),
        ('coordinator grows', 'scripts/main.gd', sources['scripts/main.gd'] + '\n' + 'var added = 0\n' * (max(400, baseline.get('files', {}).get('scripts/main.gd', {}).get('metrics', {}).get('lines', 0)) + 1), 'lines'),
        ('new widget in coordinator', 'scripts/main.gd', sources['scripts/main.gd'] + '\n' + 'func bad(): Label.new()\n' * (baseline.get('files', {}).get('scripts/main.gd', {}).get('metrics', {}).get('widget-ownership', 0) + 1), 'widget-ownership'),
    ]
    detected = []
    for name, path, source, expected in cases:
        candidate = dict(sources, **{path: source})
        errors, _ = check(candidate, baseline)
        if not any(error['rule'] == expected for error in errors): raise RuntimeError('Guard missed: ' + name)
        detected.append(name)
    candidate = dict(sources)
    candidate['scripts/battle/negative.gd'] = 'const Bad = preload("res://scripts/battle/second.gd")'
    candidate['scripts/battle/second.gd'] = 'const Bad = preload("res://scripts/battle/negative.gd")'
    if not any(error['rule'] == 'acyclic-dependencies' for error in check(candidate, baseline)[0]): raise RuntimeError('Guard missed cycle')
    return detected + ['dependency cycle']


def main():
    sources = {path.relative_to(ROOT).as_posix(): path.read_text() for path in (ROOT / 'scripts').rglob('*.gd')}
    baseline = json.loads((ROOT / 'tools/architecture-baseline.json').read_text())
    errors, debts = check(sources, baseline)
    detected = negative_checks(sources, baseline)
    report = {'suite': 'architecture', 'modules': len(sources), 'failed': len(errors), 'errors': errors, 'existing_debt': debts,
              'baseline_commit': baseline['commit'], 'negative_cases_detected': detected,
              'limits': 'Existing current-main debt is explicit. New code cannot increase its metrics; this is not proof of architectural completion.'}
    (results_dir() / 'architecture-report.json').write_text(json.dumps(report, indent=2))
    print(json.dumps(report))
    return int(bool(errors))

if __name__ == '__main__': raise SystemExit(main())
