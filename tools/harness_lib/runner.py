"""Dependency scheduling and durable run status. Focused success is never full acceptance."""
from concurrent.futures import ThreadPoolExecutor, wait, FIRST_COMPLETED
from datetime import datetime, timezone
import json
from pathlib import Path
import signal
import threading
import time
import uuid
from .executor import Executor
from .manifest import ROOT, source_manifest
from .registry import registry, closure, coverage


def atomic_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + '.tmp')
    temporary.write_text(json.dumps(value, indent=2, ensure_ascii=False))
    temporary.replace(path)


def run(requested, options=None, output=None, root=ROOT, tasks=None, executor_type=Executor):
    options = dict(options or {})
    if options.get('full') and any(options.get(key) for key in ('case', 'viewport', 'fixture', 'large_text')):
        raise ValueError('Full acceptance cannot use case, viewport or fixture filters')
    tasks = tasks or registry()
    ordered = closure(tasks, requested)
    sources = source_manifest(root)
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    label = options.get('label', 'harness')
    output = Path(output).resolve() if output else root / 'artifacts/harness' / f'{label}-{stamp}-{uuid.uuid4().hex[:6]}'
    output.mkdir(parents=True, exist_ok=False)
    (output / '.gdignore').touch()
    atomic_json(output / 'source-manifest.json', sources)
    cancelled = threading.Event()
    records = {}
    previous = {}
    if options.get('resume'):
        old = json.loads(Path(options['resume']).read_text())
        previous = old.get('tasks', {})
    report = {'schema_version': 1, 'status': 'running', 'scope': 'full' if options.get('full') else 'focused',
              'source_hash': sources['sha256'], 'requested': list(requested), 'options': options,
              'directory': str(output), 'tasks': records, 'started_utc': stamp}
    started = time.monotonic()
    executor = executor_type(root, output, sources, options, cancelled)
    report['tools'] = executor.versions
    original_signals = {}
    if threading.current_thread() is threading.main_thread():
        for name in (signal.SIGINT, signal.SIGTERM):
            original_signals[name] = signal.signal(name, lambda *_: cancelled.set())

    def persist():
        report['seconds'] = round(time.monotonic() - started, 3)
        atomic_json(output / 'harness-run.json', report)

    persist()
    running = {}
    pending = set(ordered)
    try:
        with ThreadPoolExecutor(max_workers=max(1, options.get('jobs', 3))) as pool:
            while pending or running:
                for name in ordered:
                    if name not in pending:
                        continue
                    task = tasks[name]
                    if cancelled.is_set():
                        records[name] = {'name': name, 'status': 'skipped', 'reason': 'run interrupted', 'seconds': 0}
                        pending.remove(name)
                    elif all(dependency in records for dependency in task.deps):
                        if any(records[dependency]['status'] not in ('passed', 'cached') for dependency in task.deps):
                            records[name] = {'name': name, 'status': 'skipped', 'reason': 'dependency did not pass', 'seconds': 0}
                            pending.remove(name)
                        elif len(running) < max(1, options.get('jobs', 3)) and not (task.lock and any(tasks[active].lock == task.lock for active in running.values())):
                            dependencies = {dependency: records[dependency] for dependency in task.deps}
                            reuse = previous.get(name) if not options.get('full') else None
                            future = pool.submit(executor.execute, task, dependencies, reuse)
                            running[future] = name
                            pending.remove(name)
                            if not options.get('json'): print(f'[{label}] {name}', flush=True)
                if running:
                    finished, _ = wait(running, timeout=.1, return_when=FIRST_COMPLETED)
                    for future in finished:
                        name = running.pop(future)
                        try:
                            records[name] = future.result()
                        except Exception as error:
                            records[name] = {'name': name, 'status': 'failed', 'error': str(error), 'seconds': 0}
                        if not options.get('json'): print(f'  {name}: {records[name]["status"]} ({records[name]["seconds"]}s)', flush=True)
                persist()
    finally:
        for name, handler in original_signals.items():
            signal.signal(name, handler)
        final_sources = source_manifest(root)
        report['final_source_hash'] = final_sources['sha256']
        report['source_unchanged'] = final_sources['sha256'] == sources['sha256']
        report['inputs_verified'] = all(record.get('inputs_verified', False) for record in records.values())
        report['status'] = ('interrupted' if cancelled.is_set() else 'failed'
                            if (options.get('full') and not report['source_unchanged']) or any(r['status'] not in ('passed', 'cached') for r in records.values()) else 'passed')
        report['coverage'] = coverage(records, requested, options.get('full', False))
        if options.get('full') and not report['source_unchanged']:
            report['failure'] = 'Sources changed during execution; evidence is not acceptance for a single revision.'
        if options.get('full') and (not report['source_unchanged'] or report['status'] != 'passed'):
            report['coverage']['complete'] = False
        if options.get('full') and not report['coverage']['complete']:
            report['status'] = 'failed' if report['status'] != 'interrupted' else report['status']
        persist()
    atomic_json(root / 'test-results/harness/latest-run.json', {'report': str(output / 'harness-run.json')})
    if report['status'] == 'passed' and report['coverage']['complete']:
        atomic_json(root / 'test-results/harness/accepted-source.json', sources)
    return report
