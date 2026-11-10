"""One registry owns task dependencies, reports, filters and required acceptance coverage."""
from dataclasses import dataclass
from pathlib import Path

GAME = ('content/**', 'scripts/**', 'assets/**', 'scenes/**', 'project.godot', 'export_presets.cfg')
DATA = ('content/**', 'scripts/catalog/**', 'scripts/rules.gd', 'scripts/content.gd', 'scripts/battle/**', 'scripts/expedition/**', 'scripts/session/**', 'scripts/domain/**', 'scripts/storage.gd')
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
    pattern: str = ''
    minimum: int = 1


NATIVE = {
    'content-resources': ('content_resources_test.gd', 'content_resources', ()),
    'domain-models': ('domain_models_test.gd', 'domain_models', ()),
    'harness-core': ('harness_checkpoint_test.gd', 'harness_core', ('checkpoint', 'replay', 'planner')),
    'rules': ('rules_test.gd', 'umbral_rules', ('traits_and_passives', 'budget_and_ownership', 'seed_preview_and_inputs', 'roster_and_card_cycle', 'formation_boundaries', 'swaps_and_ko', 'ko_transition_flow', 'delayed_ko_entry', 'reserve_reinsertion', 'speed_and_scopes', 'visibility', 'multiple_items', 'enemy_attributes', 'tactical_planning', 'enemy_preparation', 'capture_and_evolution', 'natures_and_reactions', 'initial_passive_usefulness', 'elemental_starters', 'battle_lifecycle', 'simulations')),
    'catalog': ('catalog_test.gd', 'catalog', ()),
    'asset-catalog': ('asset_catalog_test.gd', 'asset_catalog', ()),
    'card-visuals': ('card_visual_test.gd', 'card_visuals', ()),
    'card-ui': ('card_presentation_ui_test.gd', 'card_presentation_ui', ()),
    'card-raster': ('card_raster_test.gd', 'card_raster', ()),
    'card-input': ('card_input_test.gd', 'ui_input_flow', ()),
    'ui-state': ('ui_state_test.gd', 'ui_state', ()),
    'ui-flow': ('ui_flow_test.gd', 'ui_input_flow', ()),
    'battle-motion': ('battle_motion_test.gd', 'battle_motion', ()),
    'startup': ('startup_smoke.gd', 'scene_startup', ()),
    'refuge': ('refuge_test.gd', 'refuge', ()),
    'title': ('title_menu_test.gd', 'title_menu_scoped', ()),
    'gold-ui': ('gold_ui_test.gd', 'gold_ui', ()),
    'codex-nav': ('codex_navigation_test.gd', 'codex_navigation', ()),
    'codex-story': ('codex_story_test.gd', 'codex_story', ()),
    'settings': ('settings_menu_test.gd', 'settings_menu', ()),
    'spring-event': ('spring_event_test.gd', 'spring_event', ()),
    'expedition-rules': ('expedition_rules_test.gd', 'expedition_rules', ()),
    'expedition-save': ('expedition_save_test.gd', 'expedition_save', ()),
    'expedition-ui': ('expedition_ui_test.gd', 'expedition_ui', ()),
}
TITLE = ('asset-catalog', 'title', 'gold-ui', 'codex-nav', 'codex-story', 'settings', 'startup')
EXPEDITION = ('spring-event', 'expedition-rules', 'expedition-save', 'expedition-ui')

SCENARIOS = ('integration', 'layout', 'navigation', 'inventory', 'combat', 'rewards', 'replacement', 'persistence', 'expedition', 'title', 'cards')
FIXTURE_SCENARIOS = {'inventory', 'combat', 'rewards', 'replacement', 'cards'}


def registry():
    tasks = {
        'architecture': Task('architecture', 'python', inputs=('scripts/**', 'tools/architecture*'), script='tools/architecture_checks.py', suite='architecture', report='architecture-report.json', count='modules'),
        'catalog-authoring': Task('catalog-authoring', 'python', inputs=('content/**', 'assets/**', 'scripts/catalog/**', 'tools/umbrals.py', 'tools/content_authoring.py', 'tests/catalog_authoring_test.py', 'tests/catalog_authoring_runner.py'), script='tests/catalog_authoring_runner.py', suite='catalog_authoring', report='catalog-authoring-report.json'),
        'content-authoring': Task('content-authoring', 'python', inputs=('content/**', 'assets/runtime-lock.json', 'scripts/catalog/**', 'scripts/battle/item_effects/**', 'tools/content_authoring.py', 'tests/content_authoring_test.py', 'tests/content_authoring_runner.py'), script='tests/content_authoring_runner.py', suite='content_authoring', report='content-authoring-report.json'),
        'migration-compat': Task('migration-compat', 'python', inputs=DATA + ('project.godot', 'tests/fixtures/**', 'tests/expedition_additive_test.py', 'tests/expedition_additive_test.gd', 'tests/expedition_additive_runner.py', 'tools/content_authoring.py'), script='tests/expedition_additive_runner.py', suite='migration_compat', report='migration-compat-report.json', minimum=5),
        'assets': Task('assets', 'python', inputs=('assets/**', 'docs/assets/**', 'tools/asset*', 'tools/card_asset_pipeline.py', 'tools/normalize_atlas.py'), script='tools/asset_checks.py', suite='asset_qa', report='asset-report.json', count='source_assets'),
        'asset-unit': Task('asset-unit', 'python', inputs=('tools/asset*', 'tools/card_asset_pipeline.py', 'tools/normalize_atlas.py', 'assets/schemas/**', 'tests/test_asset_pipeline.py'), script='tools/asset_unit_checks.py', suite='asset_units', report='asset-unit-report.json'),
        'card-assets': Task('card-assets', 'python', ('import',), inputs=GAME + ('tools/card_assets.py', 'tools/card_asset_pipeline.py', 'tools/card_visual_snapshot.gd', 'tests/fixtures/**'), script='tools/card_assets.py', suite='card_assets', report='card-asset-report.json'),
        'card-asset-unit': Task('card-asset-unit', 'python', ('import',), inputs=GAME + ('tools/card_asset*', 'tools/card_visual_snapshot.gd', 'tests/test_card_assets.py', 'tests/fixtures/**'), script='tools/card_asset_unit_checks.py', suite='card_asset_units', report='card-asset-unit-report.json'),
        'card-preview-assets': Task('card-preview-assets', 'python', ('import',), inputs=GAME + ('tools/card_preview_checks.py', 'tools/card_asset_pipeline.py', 'tools/card_visual_snapshot.gd', 'tests/fixtures/**'), script='tools/card_preview_checks.py', suite='card_preview_assets', report='card-preview-report.json'),
        'harness': Task('harness', 'python', inputs=('tools/**', 'tests/harness_runner_test.py', 'tests/browser/**', 'tests/support/**'), script='tests/harness_runner_test.py', suite='harness_runner', report='harness-report.json'),
        'import': Task('import', 'import', inputs=GAME + ('tests/**', 'tools/*.gd'), cacheable=True, lock='project'),
        'mutations': Task('mutations', 'python', ('import',), inputs=DATA + ('tests/rules_test.gd', 'tests/support/**', 'tools/mutation_smoke.py'), script='tools/mutation_smoke.py', suite='umbral_mutation_smoke', report='mutation-report.json', count='detected'),
        'fixtures': Task('fixtures', 'godot', ('import',), inputs=DATA + ('tests/support/scenario_fixtures.gd', 'tools/make_fixtures.gd'), script='tools/make_fixtures.gd', suite='scenario_fixtures', report='fixture-report.json'),
        'web': Task('web', 'export', ('import',), script='Web', inputs=GAME + ('tools/build_target.py', 'tools/card_asset_pipeline.py', 'tools/card_visual_snapshot.gd'), suite='web_export', report='build-report.json', cacheable=True, lock='project', order_only=('import',)),
        'web-fixtures': Task('web-fixtures', 'export-fixtures', ('fixtures',), inputs=GAME + ('tests/browser/**', 'tests/support/scenario_fixtures.gd', 'tools/build_target.py', 'tools/card_asset_pipeline.py', 'tools/card_visual_snapshot.gd'), suite='web_export', report='build-report.json', cacheable=True, lock='project'),
        'packed-catalog': Task('packed-catalog', 'packed', ('web',), inputs=GAME + ('tools/packed_catalog_check.py', 'tools/catalog_snapshot.gd'), suite='packed_catalog', report='packed-catalog-report.json'),
        'packed-fixtures': Task('packed-fixtures', 'packed', ('web-fixtures',), inputs=GAME + ('tools/packed_catalog_check.py', 'tools/catalog_snapshot.gd'), suite='packed_catalog', report='packed-catalog-report.json'),
    }
    patterns = {
        'expedition-rules': (r'Expedition checks: (\d+); failures: (\d+)', 51),
        'expedition-save': (r'Expedition save: (\d+) assertions, (\d+) failures', 24),
        'expedition-ui': (r'Expedition UI: (\d+) assertions, (\d+) failures', 15),
    }
    for name, (script, suite, cases) in NATIVE.items():
        pattern, minimum = patterns.get(name, ('', 1))
        inherited = ('tests/ui_flow_test.gd',) if name == 'card-input' else ()
        tasks[name] = Task(name, 'native', ('import',), inputs=(DATA if name in ('rules', 'harness-core', 'expedition-rules', 'expedition-save') else GAME) + ('tests/' + script, 'tests/support/**') + inherited + (('tests/fixtures/**',) if name in ('expedition-save', 'spring-event') else ()), script='tests/' + script, suite=suite, report='suite-report.json', cases=cases, pattern=pattern, minimum=minimum)
    for name in SCENARIOS:
        dependency = 'packed-fixtures' if name in FIXTURE_SCENARIOS else 'packed-catalog'
        tasks['browser.' + name] = Task('browser.' + name, 'browser', (dependency,), inputs=GAME + ('tools/browser/session.py', 'tools/browser_smoke.py', 'tools/browser/__init__.py', 'tools/browser/scenarios/__init__.py', 'tools/refuge_browser_review.py') + (('tools/browser/' + name + '.py', 'tests/make_browser_plan.gd') if name in ('integration', 'layout') else ('tools/' + ('expedition_browser_smoke.py' if name == 'expedition' else 'title_browser_review.py'), 'tests/make_expedition_plan.gd') if name in ('expedition', 'title') else ('tools/browser/scenarios/' + name + '.py',)), script=name, suite='umbral_ui_experience', report='browser-report.json', lock='browser')
    for target in ('Linux', 'Windows'):
        tasks['build.' + target] = Task('build.' + target, 'export', ('import',), script=target, inputs=GAME + ('tools/build_target.py', 'tools/card_asset_pipeline.py', 'tools/card_visual_snapshot.gd'), suite='web_export', report='build-report.json', cacheable=True, lock='project', order_only=('import',))
    for name, task in list(tasks.items()):
        if 'import' in task.deps and not task.order_only:
            from dataclasses import replace
            tasks[name] = replace(task, order_only=('import',))
    return tasks


HEADLESS = ('architecture', 'catalog-authoring', 'content-authoring', 'migration-compat', 'assets', 'asset-unit', 'card-assets', 'card-asset-unit', 'card-preview-assets', 'harness', 'mutations') + tuple(NATIVE)
FULL = HEADLESS + ('packed-catalog', 'fixtures', 'packed-fixtures') + tuple('browser.' + name for name in SCENARIOS)


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
