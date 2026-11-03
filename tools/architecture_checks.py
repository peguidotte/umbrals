from harness_io import results_dir
"""Enforce ownership/dependency boundaries, then prove representative regressions are rejected.

This is a conservative lexical guard, not a GDScript type checker or a substitute for
Godot/behavior/browser tests. See docs/architecture-guidelines.md before changing policy.
"""
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ALLOWED = {
    'composition': {'domain', 'rules', 'catalog', 'ui', 'storage', 'session', 'platform'},
    'domain': {'domain', 'catalog'},
    'catalog': {'domain', 'catalog', 'authored'},
    'authored': {'authored', 'catalog', 'trait'},
    'trait': {'domain'},
    'rules': {'domain', 'catalog'},
    'ui': {'ui', 'rules', 'domain', 'catalog', 'storage'},
    'session': {'rules', 'domain', 'storage'},
    'platform': {'ui', 'domain', 'catalog'},
    'storage': set(),
}


def layer(path):
    if path == 'scripts/main.gd': return 'composition'
    if path == 'scripts/rules.gd': return 'rules'
    if path == 'scripts/content.gd': return 'catalog'
    if path == 'scripts/storage.gd': return 'storage'
    if path.startswith('scripts/catalog/'): return 'catalog'
    if path.startswith('content/'):
        return 'trait' if path.endswith('.gd') else 'authored'
    for name in ('domain', 'ui', 'session', 'platform'):
        if path.startswith(f'scripts/{name}/'): return name
    return None


def check(sources):
    errors, graph = [], {}

    def reject(path, code, message):
        errors.append({'file': path, 'rule': code, 'message': message})

    for path, source in sorted(sources.items()):
        owner = layer(path)
        if owner is None:
            reject(path, 'known-layer', 'Assign a documented responsibility before adding a module.')
            continue
        # Strip line comments; keep string literals for imports and copy/behavior checks.
        code = '\n'.join(line.split(' #', 1)[0] for line in source.splitlines()
                         if not line.lstrip().startswith('#'))
        graph[path] = []
        imports = re.findall(r'(?:preload\(|load\(|extends\s+)\s*["\']res://((?:scripts|content)/[^"\']+)["\']', code)
        if owner == 'authored':
            imports += re.findall(r'path=["\']res://((?:scripts|content)/[^"\']+)["\']', code)
        for dependency in imports:
            graph[path].append(dependency)
            if dependency not in sources:
                reject(path, 'dependency-exists', f'Missing dependency: {dependency}')
            elif layer(dependency) not in ALLOWED[owner]:
                reject(path, 'dependency-direction', f'{owner} may not depend on {dependency}')
        if len([line for line in code.splitlines() if line.strip()]) > (400 if owner == 'composition' else 350):
            reject(path, 'module-budget', 'Extract a coherent responsibility; do not move code into an untyped host helper.')
        if owner in {'domain', 'rules', 'catalog', 'trait'}:
            if re.search(r'\b(FileAccess|DirAccess|JavaScriptBridge|HTTPClient|HTTPRequest|AudioServer|Input|SceneTree|Node|Control)\b|\bget_tree\s*\(', code):
                reject(path, 'pure-domain', 'Domain/catalog/rules must not use scene, input, platform or storage APIs.')
        if re.search(r'(?<![\w.])(?:randf|randi|randf_range|randi_range|randomize|seed)\s*\(', code):
            reject(path, 'local-rng', 'Use a local RNG; gameplay and visual randomness must remain separate.')
        if owner == 'composition':
            if re.search(r'\b(?:Button|Label|TextureRect|VBoxContainer|HBoxContainer|PanelContainer|ColorRect|MarginContainer|HSlider|CheckButton)\.new\(', code):
                reject(path, 'coordinator-ownership', 'Build widgets inside their owning view.')
            if re.search(r'\b(?:FileAccess|DirAccess|JavaScriptBridge)\b|create_tween\(', code):
                reject(path, 'coordinator-ownership', 'Persistence, Web protocol and tweens have dedicated owners.')
        if path.startswith('scripts/ui/screens/'):
            if re.search(r'\bgame\.(?:play|toggle|redraw|choose_reward|new_run|start_encounter|use_item|equip_item)\s*\(|\bgame\.\w+(?:\[[^\n]+?\])?\s*(?:=(?!=)|\+=|-=)|\bgame\.(?:party|hand|deck|discard_pile|selected)\.(?:append|clear|erase|assign|remove_at)\(', code):
                reject(path, 'view-commands', 'Views render rules and emit intent; only the coordinator invokes game commands.')
            if re.search(r'\b(?:host|app|coordinator)\s*[:=]|get_parent\s*\(', code):
                reject(path, 'no-host-helper', 'Use explicit services/signals, not a back-reference to the coordinator.')
            if re.search(r'func _process\(.*?(?=\nfunc |\Z)', code, re.S) and 'game.' in re.search(r'func _process\(.*?(?=\nfunc |\Z)', code, re.S).group(0):
                reject(path, 'event-driven-hud', 'Refresh gameplay presentation from rule events, not frame polling.')
            if re.search(r'\b(?:FileAccess|JavaScriptBridge)\b', code):
                reject(path, 'view-platform', 'Views must use the preferences/session service, not platform APIs.')
        if path.startswith('scripts/ui/screens/') and re.search(r'game\.inventory\.(?:consume|equip|reset|modify|detach_missing)\(', code):
            reject(path, 'view-commands', 'Inventory changes also belong to session commands.')
        if path == 'scripts/ui/combat_feedback.gd' and re.search(r'Content\.power_stats|Rules\.evaluate', code):
            reject(path, 'event-feedback', 'Feedback consumes applied events, never reconstructs power effects.')
        if path.startswith('scripts/ui/') and re.search(r'Color\(["\'][0-9a-fA-F]{6}', code):
            reject(path, 'shared-style', 'Semantic UI colors belong to the authored visual style.')
        if path == 'scripts/catalog/power_definition.gd' and re.search(r'@export.*var (?:name|power_id|art_path|action_id|damage|block|heal|burn)\b', code):
            reject(path, 'power-variant', 'Share identity and compose effects instead of restoring fixed exported fields.')
        if re.search(r'\b(?:result|score|effect)\.name\s*==', code):
            reject(path, 'stable-events', 'Display text must not select behavior; use stable event IDs.')
        if re.search(r'\.stage\b|var stage\s*:', code):
            reject(path, 'form-identities', 'Use stable form IDs and declared transitions; no ordinal stage logic.')
        if re.search(r'(?:preload\(|load\(|extends\s+)\s*["\']res://tests/', code):
            reject(path, 'test-boundary', 'Test boot scenes and fixtures must not enter production dependencies.')
        if path in {'scripts/rules.gd', 'scripts/domain/mechanics.gd', 'scripts/domain/cast_evaluator.gd'} and re.search(r'Content\.(?:SPECIES|ENCOUNTERS|ITEMS)\b', code):
            reject(path, 'explicit-catalog', 'Runtime mechanics receive their catalog from the run.')
        if path == 'scripts/rules.gd' and 'func best_selection(' in code:
            reject(path, 'separate-planner', 'Automation planning belongs outside the gameplay state machine.')
        if path == 'scripts/rules.gd':
            for field, record in [('party', 'Individual'), ('hand', 'CardInstance'), ('deck', 'CardInstance'), ('discard_pile', 'CardInstance'), ('reward_offers', 'RewardOffer')]:
                if not re.search(rf'var {field}: Array\[Models\.{record}\]', code):
                    reject(path, 'typed-runtime', f'{field} must retain typed runtime records.')
    visited, active = set(), set()

    def visit(path):
        if path in active:
            reject(path, 'acyclic-dependencies', 'Dependency cycle; move shared contracts to a lower layer.')
            return
        if path in visited: return
        active.add(path)
        for dependency in graph.get(path, []): visit(dependency)
        active.remove(path)
        visited.add(path)
    for path in graph: visit(path)
    return errors


def negative_checks(sources):
    cases = [
        ('domain imports UI', 'scripts/domain/models.gd', '\nconst Bad = preload("res://scripts/ui/kit.gd")\n', 'dependency-direction'),
        ('domain uses storage', 'scripts/rules.gd', '\nfunc bad() -> void:\n\tFileAccess.open("x", 1)\n', 'pure-domain'),
        ('coordinator builds widgets', 'scripts/main.gd', '\nfunc bad() -> void:\n\tLabel.new()\n', 'coordinator-ownership'),
        ('view executes gameplay', 'scripts/ui/screens/title_screen.gd', '\nfunc bad() -> void:\n\tgame.play()\n', 'view-commands'),
        ('view mutates state', 'scripts/ui/screens/title_screen.gd', '\nfunc bad() -> void:\n\tgame.player_hp -= 3\n', 'view-commands'),
        ('helper captures host', 'scripts/ui/screens/title_screen.gd', '\nvar host: Control\n', 'no-host-helper'),
        ('copy selects behavior', 'scripts/ui/combat_feedback.gd', '\nfunc bad() -> void:\n\tif result.name == "Vínculo triplo": pass\n', 'stable-events'),
        ('ordinal forms return', 'scripts/domain/models.gd', '\nvar stage: int = 1\n', 'form-identities'),
        ('view consumes inventory', 'scripts/ui/screens/title_screen.gd', '\nfunc bad() -> void:\n\tgame.inventory.consume(1, null)\n', 'view-commands'),
        ('feedback rebuilds rules', 'scripts/ui/combat_feedback.gd', '\nfunc bad() -> void:\n\tContent.power_stats("x", null)\n', 'event-feedback'),
        ('semantic palette duplicated', 'scripts/ui/vitals.gd', '\nvar bad_color = Color("f3e6c5")\n', 'shared-style'),
        ('fixed power fields return', 'scripts/catalog/power_definition.gd', '\n@export var damage: int = 4\n', 'power-variant'),
        ('test entry enters release', 'scripts/main.gd', '\nconst Bad = preload("res://tests/browser/fixture_entry.gd")\n', 'test-boundary'),
        ('global runtime catalog returns', 'scripts/rules.gd', '\nfunc bad() -> void:\n\tprint(Content.SPECIES)\n', 'explicit-catalog'),
        ('planner grows rules again', 'scripts/rules.gd', '\nfunc best_selection() -> Array:\n\treturn []\n', 'separate-planner'),
        ('global RNG', 'scripts/rules.gd', '\nfunc bad() -> void:\n\trandf()\n', 'local-rng'),
        ('import cycle', 'scripts/domain/models.gd', '\nconst Bad = preload("res://scripts/content.gd")\n', 'acyclic-dependencies'),
        ('coordinator grows again', 'scripts/main.gd', '\n' + 'var extra: int = 0\n' * 401, 'module-budget'),
    ]
    detected = []
    for name, target, addition, expected in cases:
        changed = dict(sources)
        changed[target] += addition
        if not any(item['rule'] == expected for item in check(changed)):
            raise RuntimeError(f'Architectural regression was not detected: {name}')
        detected.append(name)
    changed = dict(sources)
    changed['scripts/rules.gd'] = changed['scripts/rules.gd'].replace('var party: Array[Models.Individual]', 'var party: Array')
    if not any(item['rule'] == 'typed-runtime' for item in check(changed)):
        raise RuntimeError('Untyped runtime regression was not detected')
    return detected + ['runtime loses types']


def main():
    sources = {str(path.relative_to(ROOT)): path.read_text() for folder in ['scripts', 'content'] for path in (ROOT / folder).rglob('*') if path.suffix in {'.gd', '.tres'}}
    errors = check(sources)
    detected = negative_checks(sources) if not errors else []
    report = {'suite': 'architecture', 'modules': len(sources), 'failed': len(errors), 'errors': errors, 'negative_cases_detected': detected}
    output = results_dir() / 'architecture-report.json'
    output.parent.mkdir(exist_ok=True)
    output.write_text(json.dumps(report, indent=2, ensure_ascii=False))
    print(json.dumps(report, ensure_ascii=False))
    return int(bool(errors))


if __name__ == '__main__':
    raise SystemExit(main())
