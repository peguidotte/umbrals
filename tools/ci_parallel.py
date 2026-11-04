"""Run CI browser groups against one verified preparation and aggregate full evidence."""
import argparse
from datetime import datetime, timezone
import json
import os
import shutil
import subprocess
from pathlib import Path
import threading

from harness_lib.executor import Executor
from harness_lib.manifest import ROOT, digest, file_hashes, source_manifest
from harness_lib.registry import FULL, HEADLESS, SCENARIOS, coverage, registry
from harness_lib.runner import atomic_json, run

GROUPS = {
    'integration': ('integration',),
    'layout': ('layout',),
    'expedition': ('expedition',),
    'other': tuple(name for name in SCENARIOS if name not in ('integration', 'layout', 'expedition')),
}
PREPARE = tuple(HEADLESS) + ('packed-catalog', 'fixtures', 'packed-fixtures')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def relocate(report, destination):
    old = Path(report['directory'])
    for record in report['tasks'].values():
        for key in ('directory', 'build_directory'):
            if key in record:
                path = Path(record[key])
                require(path.is_relative_to(old), 'Output path escapes its run')
                record[key] = str(destination / path.relative_to(old))
    report['directory'] = str(destination)
    return report


def verify_run(report, folder, expected, source, versions=None):
    require(report.get('status') == 'passed' and report.get('source_unchanged') is True, 'Run failed or sources changed')
    require(report.get('source_hash') == source == report.get('final_source_hash'), 'Stale or mixed source')
    if versions is not None:
        require(report.get('tools') == versions, 'Mixed tool versions')
    require(set(report.get('requested', [])) == set(expected) and len(report['requested']) == len(expected), 'Missing or duplicate requested tasks')
    tasks = registry()
    from harness_lib.registry import closure
    require(set(report['tasks']) == set(closure(tasks, expected)), 'Missing or extra task records')
    for name, record in report['tasks'].items():
        require(record.get('name') == name and record.get('status') == 'passed' and record.get('inputs_verified') is True, 'Failed or unverified task: ' + name)
        directory = Path(record['directory'])
        require(directory.is_relative_to(folder) and directory.is_dir(), 'Missing task directory: ' + name)
        require(file_hashes(directory) == record.get('outputs'), 'Tampered task outputs: ' + name)
        if tasks[name].report:
            require(json.loads((directory / tasks[name].report).read_text()) == record.get('report'), 'Report differs from task output: ' + name)


def preparation_digest(report):
    return digest({name: {key: value for key, value in record.items() if key not in ('directory', 'build_directory', 'command')}
                   for name, record in report['tasks'].items()})


def identity():
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    require(not os.environ.get('GITHUB_SHA') or os.environ['GITHUB_SHA'] == commit, 'Checkout differs from workflow commit')
    return {'commit': commit, 'run_id': os.environ.get('GITHUB_RUN_ID', 'local'),
            'run_attempt': os.environ.get('GITHUB_RUN_ATTEMPT', 'local')}


def verified_manifest(folder, expected):
    manifest = json.loads((folder / 'source-manifest.json').read_text())
    require(manifest.get('sha256') == expected and digest(manifest.get('files')) == expected,
            'Source manifest does not match the frozen source')
    return manifest


def preparation(folder):
    report = relocate(json.loads((folder / 'harness-run.json').read_text()), folder)
    current = source_manifest()
    source = current['sha256']
    require(verified_manifest(folder, source) == current, 'Source manifest differs from checkout')
    require(report.get('ci_identity') == identity(), 'Stale or mixed workflow identity')
    verify_run(report, folder, PREPARE, source)
    return report


def prepare(folder):
    result = run(list(PREPARE), {'label': 'ci-prepare', 'fresh': True, 'video': True, 'jobs': 3}, folder)
    result['ci_identity'] = identity()
    atomic_json(folder / 'harness-run.json', result)
    require(result['status'] == 'passed' and result['source_unchanged'], 'Preparation failed')


def shard(folder, prepared, group):
    prep = preparation(prepared)
    sources = source_manifest()
    options = {'label': 'ci-' + group, 'video': True, 'fresh': True}
    folder.mkdir(parents=True, exist_ok=False)
    (folder / '.gdignore').touch()
    executor = Executor(ROOT, folder, sources, options, threading.Event())
    require(executor.versions == prep['tools'], 'Mixed tool versions')
    tasks = registry()
    records = {}
    for scenario in GROUPS[group]:
        task = tasks['browser.' + scenario]
        record = executor.execute(task, {name: prep['tasks'][name] for name in task.deps})
        records[task.name] = record
        print(f'[{group}] {task.name}: {record["status"]} ({record.get("seconds", 0)}s)', flush=True)
        if record.get('log_excerpt'):
            print(f'--- {task.name} failure log (last 12000 bytes) ---\n{record["log_excerpt"]}', flush=True)
    final = source_manifest()['sha256']
    result = {'status': 'passed' if all(x['status'] == 'passed' for x in records.values()) and final == sources['sha256'] else 'failed',
              'source_hash': sources['sha256'], 'final_source_hash': final, 'source_unchanged': final == sources['sha256'],
              'tools': executor.versions, 'ci_identity': identity(), 'group': group, 'preparation_digest': preparation_digest(prep),
              'directory': str(folder), 'tasks': records}
    atomic_json(folder / 'shard.json', result)
    require(result['status'] == 'passed', 'Browser group failed')


def aggregate(prepared, shards, output, report_path=None):
    prep = preparation(prepared)
    versions, source = prep['tools'], prep['source_hash']
    require(len(shards) == len(GROUPS), 'Missing or duplicate browser groups')
    seen, records = set(), dict(prep['tasks'])
    for folder in shards:
        shard_report = relocate(json.loads((folder / 'shard.json').read_text()), folder)
        group = shard_report.get('group')
        require(group in GROUPS and group not in seen, 'Missing or duplicate browser group')
        seen.add(group)
        require(shard_report.get('status') == 'passed' and shard_report.get('source_unchanged') is True, 'Browser group failed')
        require(shard_report.get('source_hash') == source == shard_report.get('final_source_hash'), 'Stale or mixed source')
        require(shard_report.get('ci_identity') == prep['ci_identity'], 'Stale or mixed workflow identity')
        require(shard_report.get('tools') == versions and shard_report.get('preparation_digest') == preparation_digest(prep), 'Mixed tools or preparation')
        expected = {'browser.' + name for name in GROUPS[group]}
        require(set(shard_report['tasks']) == expected, 'Missing or extra browser scenarios')
        for name, record in shard_report['tasks'].items():
            require(record.get('name') == name and record.get('status') == 'passed' and record.get('inputs_verified') is True, 'Failed browser scenario: ' + name)
            directory = Path(record['directory'])
            require(directory.is_relative_to(folder) and directory.is_dir() and file_hashes(directory) == record.get('outputs'), 'Tampered browser output: ' + name)
            require(json.loads((directory / 'browser-report.json').read_text()) == record.get('report'), 'Browser report mismatch: ' + name)
            report = record['report']
            require(report.get('suite') == 'umbral_ui_experience' and report.get('scenario') == name[8:] and report.get('checks', 0) > 0 and report.get('failed') == 0, 'Invalid browser report: ' + name)
            require(record.get('arguments') == {'viewport': None, 'large_text': None, 'fixture': None, 'video': True}, 'Filtered browser scenario: ' + name)
            records[name] = record
    require(seen == set(GROUPS), 'Missing browser groups')
    layout = records['browser.layout']['report']
    expected_viewports = json.loads((ROOT / 'docs/ux-contracts.json').read_text())['viewports']
    matrix = layout.get('matrix', [])
    require(layout.get('matrix_executed') is True and len(matrix) == len(expected_viewports) and
            {tuple(sorted(row['viewport'].items())) for row in matrix if row.get('status') == 'passed'} ==
            {(('height', height), ('width', width)) for width, height in expected_viewports}, 'Viewport matrix incomplete')
    require((Path(records['browser.integration']['directory']) / 'gameplay.webm').is_file(), 'Missing gameplay video')
    frozen = verified_manifest(prepared, source)
    output.mkdir(parents=True, exist_ok=False)
    (output / '.gdignore').touch()
    shutil.copy2(prepared / 'source-manifest.json', output / 'source-manifest.json')
    require(verified_manifest(output, source) == frozen, 'Copied source manifest differs')
    started = datetime.strptime(prep['started_utc'], '%Y%m%dT%H%M%S%fZ').replace(tzinfo=timezone.utc)
    elapsed = round((datetime.now(timezone.utc) - started).total_seconds(), 3)
    require(elapsed >= 0, 'Preparation start time is in the future')
    combined = dict(prep, scope='full', requested=list(FULL), tasks=records, directory=str(output),
                    seconds=elapsed, execution_mode='distributed fresh full acceptance',
                    options={'label': 'ci', 'full': True, 'fresh': True, 'video': True},
                    coverage=coverage(records, FULL, True))
    require(combined['coverage']['complete'], 'Full coverage incomplete')
    from harness_lib.reporting import summarize
    from iterate import write_review
    result = summarize(combined)
    result['goal'] = 'Preservar regras, navegação, saves e experiência em cinco formatos de tela'
    atomic_json(output / 'harness-run.json', combined)
    atomic_json(output / 'run.json', result)
    atomic_json(report_path or ROOT / 'test-results/ci-run.json', result)
    write_review(output, result)
    from harness_lib.builds import publish_build
    publish_build(records['web']['build_directory'], 'Web')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    p = sub.add_parser('prepare'); p.add_argument('--output', type=Path, required=True)
    p = sub.add_parser('shard'); p.add_argument('--prepared', type=Path, required=True); p.add_argument('--group', choices=GROUPS, required=True); p.add_argument('--output', type=Path, required=True)
    p = sub.add_parser('aggregate'); p.add_argument('--prepared', type=Path, required=True); p.add_argument('--shard', type=Path, action='append', required=True); p.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.command == 'prepare': prepare(args.output.resolve())
        elif args.command == 'shard': shard(args.output.resolve(), args.prepared.resolve(), args.group)
        else: aggregate(args.prepared.resolve(), [p.resolve() for p in args.shard], args.output.resolve())
    except (ValueError, OSError, KeyError, TypeError) as error:
        parser.exit(1, f'CI validation failed: {error}\n')


if __name__ == '__main__':
    main()
