"""One registry owns task dependencies, reports, filters and required acceptance coverage."""
from dataclasses import dataclass
from pathlib import Path

GAME = ('scripts/**', 'content/**', 'assets/**', 'scenes/**', 'project.godot', 'export_presets.cfg')
DATA = ('scripts/domain/**', 'scripts/catalog/**', 'scripts/content.gd', 'scripts/rules.gd', 'scripts/session/run_replay.gd', 'content/**')
POLICY = ('AGENTS.md', '.agents/skills/umbral/**', 'docs/architecture*.md', 'docs/ux-contracts.json')
INFRA = ('tools/harness.py', 'tools/harness_io.py', 'tools/harness_lib/**')


@dataclass(frozen=True)
class Task:
    name: str
    kind: str
    deps: tuple = ()
    inputs: tuple = GAME
    script: str = ''
    suite: str = ''
    report: str = ''
    count: str = 'checks'
    cases: tuple = ()
    cacheable: bool = False
    lock: str = ''
    order_only: tuple = ()


NATIVE = {
    'rules': ('rules_test.gd', 'umbral_rules', ('traits', 'individual_passives', 'energy_and_ownership', 'determinism_and_inputs', 'round_resolution', 'capture_and_evolution', 'simulations')),
    'effects': ('growth_contracts_test.gd', 'growth_contracts', ('enemy_shield', 'statuses', 'powers_and_enemies', 'inventory', 'validation')),
    'harness-core': ('harness_core_test.gd', 'harness_core', ('catalog_isolation', 'planner', 'snapshot', 'reward_checkpoint', 'replay')),
    'domain': ('domain_contracts_test.gd', 'domain_contracts', ()),
    'evolution': ('evolution_graph_test.gd', 'evolution_graph', ()),
    'creatures': ('creature_gallery_test.gd', 'creature_gallery', ()),
    'species-ui': ('species_ui_growth_test.gd', 'species_ui_growth', ()),
    'inventory': ('growth_ui_test.gd', 'growth_ui', ()),
    'ui-state': ('ui_state_test.gd', 'ui_state', ()),
    'ui-flow': ('ui_flow_test.gd', 'ui_input_flow', ()),
    'lifecycle': ('lifecycle_test.gd', 'session_lifecycle', ()),
    'startup': ('startup_smoke.gd', 'scene_startup', ()),
}
SCENARIOS = ('navigation', 'inventory', 'combat', 'rewards', 'replacement', 'persistence', 'layout', 'integration')
FIXTURE_SCENARIOS = {'inventory', 'combat', 'rewards', 'replacement'}


def registry():
    tasks = {
        'architecture': Task('architecture', 'python', inputs=('scripts/**', 'content/**', 'tools/architecture_checks.py'), script='tools/architecture_checks.py', suite='architecture', report='architecture-report.json', count='modules'),
        'assets': Task('assets', 'python', inputs=('assets/**', 'content/**', 'tools/asset_checks.py'), script='tools/asset_checks.py', suite='asset_qa', report='asset-report.json', count='source_assets'),
        'harness': Task('harness', 'python', inputs=('tools/**', 'tests/harness_runner_test.py', 'tests/browser/**', 'tests/support/**'), script='tests/harness_runner_test.py', suite='harness_runner', report='harness-report.json'),
        'import': Task('import', 'import', inputs=GAME + ('tests/**', 'tools/*.gd'), cacheable=True, lock='project'),
        'content': Task('content', 'godot', ('import',), script='tools/content_checks.gd', suite='content_packages', report='content-report.json'),
        'authoring': Task('authoring', 'python', ('import',), inputs=GAME + ('tools/author*', 'tools/package_validation.gd', 'tools/content_checks.gd'), script='tools/authoring_smoke.py', suite='authoring_smoke', report='authoring-report.json'),
        'mutations': Task('mutations', 'python', ('import',), inputs=DATA + ('tests/rules_test.gd', 'tests/support/**', 'tools/mutation_smoke.py'), script='tools/mutation_smoke.py', suite='umbral_mutation_smoke', report='mutation-report.json', count='detected'),
        'fixtures': Task('fixtures', 'godot', ('import',), inputs=DATA + ('tests/support/scenario_fixtures.gd', 'tools/make_fixtures.gd'), script='tools/make_fixtures.gd', suite='scenario_fixtures', report='fixture-report.json'),
        'web': Task('web', 'export', ('import',), script='Web', inputs=GAME + ('tools/build_target.py',), suite='web_export', report='build-report.json', cacheable=True, lock='project', order_only=('import',)),
        'web-fixtures': Task('web-fixtures', 'export-fixtures', ('fixtures',), inputs=GAME + ('tests/browser/fixture_entry.*', 'tests/support/scenario_fixtures.gd', 'tools/build_target.py'), suite='web_export', report='build-report.json', cacheable=True, lock='project'),
        'packed-catalog': Task('packed-catalog', 'packed', ('web',), inputs=GAME + ('tools/packed_catalog_check.py', 'tools/catalog_snapshot.gd'), suite='packed_catalog', report='packed-catalog-report.json'),
        'packed-fixtures': Task('packed-fixtures', 'packed', ('web-fixtures',), inputs=GAME + ('tools/packed_catalog_check.py', 'tools/catalog_snapshot.gd'), suite='packed_catalog', report='packed-catalog-report.json'),
        'gallery': Task('gallery', 'gallery', ('import',), inputs=GAME + ('tools/preview_style_gallery.py',), suite='style_gallery', report='gallery-report.json', lock='browser'),
    }
    for name, (script, suite, cases) in NATIVE.items():
        tasks[name] = Task(name, 'native', ('import',), inputs=(DATA if name in ('rules', 'effects', 'harness-core', 'domain', 'evolution') else GAME) + ('tests/' + script, 'tests/support/**'), script='tests/' + script, suite=suite, report='suite-report.json', cases=cases)
    for name in SCENARIOS:
        dependency = 'packed-fixtures' if name in FIXTURE_SCENARIOS else 'packed-catalog'
        tasks['browser.' + name] = Task('browser.' + name, 'browser', (dependency,), inputs=GAME + ('docs/art-direction-v0.3.md', 'tools/browser/session.py', 'tools/browser_smoke.py', 'tools/browser/__init__.py', 'tools/browser/' + (name + '.py' if name in ('integration', 'layout') else 'scenarios/' + name + '.py'), 'tools/browser/scenarios/common.py', 'tools/browser/scenarios/__init__.py') + (('tests/make_browser_plan.gd', 'tests/support/case_selection.gd') if name == 'integration' else ()), script=name, suite='umbral_ui_experience', report='browser-report.json', lock='browser')
    for target in ('Linux', 'Windows'):
        tasks['build.' + target] = Task('build.' + target, 'export', ('import',), script=target, inputs=GAME + ('tools/build_target.py',), suite='web_export', report='build-report.json', cacheable=True, lock='project', order_only=('import',))
    for name, task in list(tasks.items()):
        if 'import' in task.deps and not task.order_only:
            from dataclasses import replace
            tasks[name] = replace(task, order_only=('import',))
    return tasks


HEADLESS = ('architecture', 'assets', 'harness', 'content', 'authoring', 'mutations') + tuple(NATIVE)
FULL = HEADLESS + ('packed-catalog', 'fixtures', 'packed-fixtures', 'gallery') + ('browser.integration',) + tuple('browser.' + name for name in SCENARIOS if name != 'integration')


def closure(tasks, requested):
    result, active, visited = [], set(), set()

    def visit(name):
        if name not in tasks:
            raise ValueError('Unknown task: ' + name)
        if name in active:
            raise ValueError('Cyclic task dependency: ' + name)
        if name in visited:
            return
        active.add(name)
        for dependency in tasks[name].deps:
            visit(dependency)
        active.remove(name)
        visited.add(name)
        result.append(name)
    for name in requested:
        visit(name)
    return result


def coverage(records, requested, full=False):
    complete = set(FULL).issubset(requested) and all(records.get(name, {}).get('status') in ('passed', 'cached') for name in FULL)
    # Full acceptance always executes behavior anew; cache is for prerequisites/artifacts only.
    if full:
        complete = complete and all(records[name]['status'] == 'passed' for name in FULL if not registry()[name].cacheable)
    return {'scope': 'full' if full else 'focused', 'complete': bool(full and complete), 'required': list(FULL) if full else list(requested)}
