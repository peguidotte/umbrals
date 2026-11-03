"""Umbral tasks: list, plan, focused checks/browser, replay, checked resume, full acceptance."""
import argparse
from dataclasses import replace
import json
import os
from pathlib import Path
import re
import sys
from harness_lib.manifest import ROOT
from harness_lib.registry import registry, HEADLESS, FULL, SCENARIOS, Task
from harness_lib.planning import plan
from harness_lib.runner import run, atomic_json
from harness_lib.reporting import summarize
from harness_lib.builds import publish_build


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    sub = result.add_subparsers(dest='command', required=True)
    for name in ['list', 'preflight', 'plan', 'check', 'browser', 'verify', 'build', 'resume', 'replay']:
        command = sub.add_parser(name)
        command.add_argument('--json', action='store_true')
        if name == 'preflight': command.add_argument('--fetch', action='store_true')
        if name in ['plan', 'check']:
            command.add_argument('--suite', action='append')
        if name == 'plan':
            command.add_argument('--changed', action='store_true')
            command.add_argument('--since', type=Path)
        if name == 'check': command.add_argument('--case')
        if name == 'browser':
            command.add_argument('--scenario', choices=SCENARIOS, required=True)
            command.add_argument('--viewport')
            command.add_argument('--large-text', action='store_true')
            command.add_argument('--fixture')
        if name == 'build': command.add_argument('target', choices=['Web', 'Windows', 'Linux'])
        if name == 'verify': command.add_argument('--full', action='store_true', required=True)
        if name == 'resume':
            command.add_argument('--from', dest='previous', type=Path, required=True)
            command.add_argument('--task', help='Rerun one registered task and its dependencies as focused evidence.')
        if name == 'replay': command.add_argument('--input', type=Path, required=True)
        if name not in ['list', 'plan', 'preflight']:
            command.add_argument('--output', type=Path)
            command.add_argument('--jobs', type=int, default=3)
            command.add_argument('--step-timeout', type=int, default=1800)
            command.add_argument('--label', default='harness-' + name)
            command.add_argument('--fresh', action='store_true')
            command.add_argument('--video', action='store_true')
            command.add_argument('--report-file', type=Path)
    return result


def suites(values):
    if not values: return list(HEADLESS)
    return list(dict.fromkeys(name for value in values for name in value.split(',')))


def main(argv=None):
    cli = parser()
    args = cli.parse_args(argv)
    tasks = registry()
    options = vars(args).copy()
    options = {key: str(value) if isinstance(value, Path) else value for key, value in options.items()}
    if args.command == 'preflight':
        from harness_lib.preflight import inspect
        result = inspect(ROOT, args.fetch)
        print(json.dumps(result, indent=2, ensure_ascii=False))
        return 2 if result['behind'] else 0
    if args.command == 'list':
        print(json.dumps({'tasks': {name: {'dependencies': task.deps, 'cases': task.cases, 'cacheable': task.cacheable} for name, task in tasks.items()}, 'headless': HEADLESS, 'full': FULL}, indent=2))
        return 0
    if args.command == 'plan':
        if args.changed and args.suite: cli.error('Use explicit suites or --changed, not both')
        result = plan(suites(args.suite) if args.suite else HEADLESS, args.changed, args.since)
        print(json.dumps(result, indent=2, ensure_ascii=False))
        return 0
    if not re.fullmatch(r'[a-zA-Z0-9][a-zA-Z0-9._-]{0,60}', args.label): cli.error('Invalid short label')
    if args.step_timeout < 60: cli.error('--step-timeout must be at least 60 seconds')
    if args.jobs < 1 or args.jobs > 8: cli.error('--jobs must be between 1 and 8')
    if args.command == 'check':
        requested = suites(args.suite)
        if args.case:
            if len(requested) != 1 or requested[0] not in tasks or args.case not in tasks[requested[0]].cases:
                cli.error('--case requires one compatible suite; use list to inspect case names')
            options['case_task'] = requested[0]
    elif args.command == 'browser':
        if args.viewport and args.scenario in ('title', 'expedition'): cli.error('This scenario owns its viewport coverage; use layout for a filtered viewport')
        if args.viewport and not re.fullmatch(r'\d{3,4}x\d{3,4}', args.viewport): cli.error('Use --viewport WIDTHxHEIGHT')
        allowed_fixtures = {'inventory': {'wounded', 'inventory_full'}, 'combat': {'battle', 'wounded', 'enemy_shield'}, 'rewards': {'rewards', 'rewards_many'}, 'replacement': {'replacement'}}
        if args.fixture and args.fixture not in allowed_fixtures.get(args.scenario, set()): cli.error('Fixture is not compatible with this scenario')
        if args.large_text and args.scenario not in allowed_fixtures: cli.error('--large-text applies to fixture scenarios; layout already exercises both scales')
        requested = ['browser.' + args.scenario]
    elif args.command == 'verify':
        requested = list(FULL)
    elif args.command == 'build':
        requested = ['packed-catalog'] if args.target == 'Web' else ['build.' + args.target]
    elif args.command == 'resume':
        path = args.previous / 'harness-run.json' if args.previous.is_dir() else args.previous
        previous = json.loads(path.read_text())
        requested = previous['requested']
        options = {**previous['options'], **options, 'resume': str(path), 'full': previous['scope'] == 'full', 'force_tasks': []}
        if args.task:
            if args.task not in tasks: cli.error('Unknown task: ' + args.task)
            requested = [args.task]
            options.update(full=False, case=None, case_task=None, viewport=None, fixture=None, large_text=False, force_tasks=[args.task])
    else:
        if not args.input.is_file(): cli.error('Replay file does not exist')
        tasks['replay'] = Task('replay', 'replay', ('import',), script='tools/replay_run.gd', suite='run_replay', report='suite-report.json')
        requested = ['replay']
    try:
        result = run(requested, options, args.output, tasks=tasks)
    except (ValueError, OSError) as error:
        cli.error(str(error))
    result = summarize(result)
    if args.report_file: atomic_json(args.report_file, result)
    if args.command == 'verify' and result['status'] == 'passed':
        publish_build(result['tasks']['web']['build_directory'], 'Web')
    if args.command == 'build' and result['status'] == 'passed':
        key = 'web' if args.target == 'Web' else 'build.' + args.target
        publish_build(result['tasks'][key]['build_directory'], args.target)
    if args.json:
        print(json.dumps(result, ensure_ascii=False))
        return 130 if result['status'] == 'interrupted' else 0 if result['status'] == 'passed' else 1
    print(json.dumps({'status': result['status'], 'scope': result['scope'], 'complete': result['coverage']['complete'],
                      'seconds': result['seconds'], 'report': str(Path(result['directory']) / 'harness-run.json')}, ensure_ascii=False))
    return 130 if result['status'] == 'interrupted' else 0 if result['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
