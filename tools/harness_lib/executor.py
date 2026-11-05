"""Execute one registered task with locks, isolated outputs, bounded processes and checked cache."""
from contextlib import contextmanager
import fcntl
import importlib.metadata
import json
import os
import re
from pathlib import Path
import signal
import subprocess
import sys
import time
import shutil
from .manifest import digest, matches, file_hashes, source_manifest
from harness_lib.browser_runtime import chromium_executable


def environment(root):
    env = dict(os.environ)
    state = Path(env.get('FERAL_STATE_ROOT', '/workspace' if Path('/workspace').exists() else str(Path.home())))
    env['PATH'] = str(state / '.local/bin') + os.pathsep + env.get('PATH', '')
    for field, suffix in [('XDG_DATA_HOME', '.local/share'), ('XDG_CONFIG_HOME', '.config'), ('XDG_CACHE_HOME', '.cache')]:
        env.setdefault(field, str(state / suffix))
    env.setdefault('PLAYWRIGHT_BROWSERS_PATH', str(Path(env['XDG_CACHE_HOME']) / 'ms-playwright'))
    return env


def fatal_engine_output(output):
    return output.startswith('ERROR:') or any(marker in output for marker in
        ('SCRIPT ERROR:', '\nERROR:', 'instances leaked', 'Resources still in use'))


def stop_process_group(process):
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        process.wait()
        return
    try:
        process.wait(timeout=3)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait()


class Executor:
    def __init__(self, root, out, sources, options, cancelled):
        self.root, self.out, self.sources, self.options, self.cancelled = root, out, sources, options, cancelled
        self.cache = root / 'test-results/harness/cache'
        self.locks = root / 'test-results/harness/locks'
        self.env = environment(root)
        self.versions = {'python': sys.version.split()[0]}
        for package in ['playwright', 'Pillow']:
            try:
                self.versions[package] = importlib.metadata.version(package)
            except importlib.metadata.PackageNotFoundError:
                self.versions[package] = 'unavailable'
        try:
            self.versions['godot'] = subprocess.run(['godot', '--version'], env=self.env, capture_output=True, text=True, timeout=15).stdout.strip() or 'unavailable'
        except OSError:
            self.versions['godot'] = 'unavailable'
        chromium = chromium_executable(self.env)
        self.versions['chromium'] = subprocess.run([chromium, '--version'], env=self.env, capture_output=True, text=True, timeout=15).stdout.strip() if chromium else 'playwright-bundled'

    def arguments(self, task):
        if task.kind == 'native' and task.name == self.options.get('case_task'):
            return {'case': self.options.get('case', '')}
        if task.kind == 'browser':
            return {key: self.options.get(key) for key in ('viewport', 'large_text', 'fixture', 'video')}
        if task.kind == 'replay':
            path = Path(self.options['input']).resolve()
            return {'input': __import__('hashlib').sha256(path.read_bytes()).hexdigest()}
        return {}

    def fingerprint(self, task, dependencies, sources=None):
        from .registry import INFRA, POLICY
        inputs = {name: value for name, value in (sources or self.sources)['files'].items() if matches(name, task.inputs + INFRA + POLICY)}
        deps = {name: {'fingerprint': record['fingerprint'], 'outputs': self.semantic_outputs(record)}
                for name, record in dependencies.items() if name not in task.order_only}
        return digest({'task': task.name, 'kind': task.kind, 'inputs': inputs, 'dependencies': deps,
                       'arguments': self.arguments(task), 'versions': self.versions})

    @staticmethod
    def semantic_outputs(record):
        return {name: value for name, value in record.get('outputs', {}).items()
                if not name.endswith(('.log', '.webm')) and not name.startswith('userdata/')}

    @contextmanager
    def locked(self, name):
        if not name:
            yield
            return
        self.locks.mkdir(parents=True, exist_ok=True)
        with (self.locks / (name + '.lock')).open('a') as handle:
            while True:
                if self.cancelled.is_set():
                    raise InterruptedError('Run interrupted while waiting for ' + name)
                try:
                    fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    break
                except BlockingIOError:
                    time.sleep(.05)
            try:
                yield
            finally:
                fcntl.flock(handle, fcntl.LOCK_UN)

    def command(self, task, folder, deps):
        base = ['godot', '--headless', '--path', str(self.root)]
        if task.kind == 'import':
            return base + ['--editor', '--import', '--quit']
        if task.kind in ('native', 'godot'):
            result = base + ['--script', task.script]
            if self.arguments(task).get('case'):
                result += ['--', '--case', self.options['case']]
            return result
        if task.kind == 'python':
            return [sys.executable, task.script]
        if task.kind in ('export', 'export-fixtures'):
            result = [sys.executable, 'tools/build_target.py', '--target', task.script or 'Web', '--output', str(folder / 'build')]
            if task.kind == 'export-fixtures':
                result += ['--fixture-data', str(Path(deps['fixtures']['directory']) / 'fixtures.json')]
            return result
        if task.kind == 'packed':
            dependency = next(iter(deps.values()))
            result = [sys.executable, 'tools/packed_catalog_check.py', str(Path(dependency['directory']) / 'build/index.pck')]
            return result + (['--fixtures'] if 'web-fixtures' in deps else [])
        if task.kind == 'gallery':
            return [sys.executable, 'tools/preview_style_gallery.py', '--output', str(folder)]
        if task.kind == 'replay':
            return base + ['--script', 'tools/replay_run.gd', '--', '--input', str(Path(self.options['input']).resolve())]
        if task.kind == 'browser':
            packed = next(iter(deps.values()))
            build = packed['build_directory']
            result = [sys.executable, 'tools/browser_smoke.py', '--scenario', task.script, '--build-dir', build, '--output', str(folder)]
            for key, flag in [('viewport', '--viewport'), ('fixture', '--fixture')]:
                if self.options.get(key): result += [flag, self.options[key]]
            if self.options.get('large_text'): result.append('--large-text')
            if self.options.get('video'): result.append('--video')
            return result
        raise ValueError('Unknown execution kind: ' + task.kind)

    def process(self, command, folder, task):
        env = dict(self.env, UMBRAL_RESULTS_DIR=str(folder))
        if task.kind == 'native':
            for variable, subdirectory in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
                env[variable] = str(folder / 'userdata' / subdirectory)
        timeout = self.options.get('step_timeout', 1800) if task.kind == 'browser' else 240
        started = time.monotonic()
        log_path = folder / 'process.log'
        with log_path.open('w') as log, log_path.open(errors='replace') as observed:
            process = subprocess.Popen(command, cwd=self.root, env=env, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
            tail = ''
            while process.poll() is None:
                if self.cancelled.is_set() or time.monotonic() - started > timeout:
                    stop_process_group(process)
                    if self.cancelled.is_set(): raise InterruptedError('Run interrupted')
                    raise TimeoutError(f'Task exceeded {timeout}s')
                tail += observed.read(65536)
                if fatal_engine_output(tail):
                    stop_process_group(process)
                    raise RuntimeError(f'Fatal engine error; see {log_path}')
                tail = tail[-512:]
                time.sleep(.05)
        output = log_path.read_text()
        if process.returncode or fatal_engine_output(output):
            raise RuntimeError(f'Command failed ({process.returncode}); see {folder / "process.log"}')
        return output

    def validate(self, task, folder, output=''):
        path = folder / (task.report or 'suite-report.json')
        if task.pattern:
            matches = re.findall(task.pattern, output)
            if len(matches) != 1: raise ValueError('Expected one current native summary: ' + task.name)
            count, failures = map(int, matches[0])
            path.write_text(json.dumps({'suite': task.suite, 'checks': count, 'failed': failures}))
        elif task.kind in ('native', 'replay'):
            candidates = []
            for line in output.splitlines():
                try:
                    value = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if isinstance(value, dict) and value.get('suite') == task.suite:
                    candidates.append(value)
            if len(candidates) != 1:
                raise ValueError('Expected one executed suite report: ' + task.suite)
            path.write_text(json.dumps(candidates[0], indent=2))
        elif task.kind == 'import':
            path.write_text(json.dumps({'suite': 'import', 'checks': 1, 'failed': 0}))
        report = json.loads(path.read_text())
        count = report.get(task.count, 0)
        count = len(count) if isinstance(count, list) else count
        if task.kind == 'gallery':
            count = len(report.get('captures', []))
        if count < task.minimum or report.get('failed', 0) != 0 or (task.suite and report.get('suite') != task.suite):
            raise ValueError('Empty, mismatched or failed report: ' + task.name)
        case = self.arguments(task).get('case')
        if case and (report.get('case') != case or report.get('cases') != [case]):
            raise ValueError('Requested case was not exclusively executed')
        return report

    def checked_copy(self, origin, hashes, target):
        if not origin.is_dir() or file_hashes(origin) != hashes:
            return False
        shutil.copytree(origin, target, dirs_exist_ok=True)
        return True

    def execute(self, task, deps, previous=None):
        started = time.monotonic()
        folder = self.out / 'tasks' / task.name
        folder.mkdir(parents=True)
        key = self.fingerprint(task, deps)
        record = {'name': task.name, 'status': 'failed', 'directory': str(folder), 'fingerprint': key,
                  'arguments': self.arguments(task), 'dependencies': list(deps), 'source_hash': self.sources['sha256']}
        store = self.cache / task.name / key
        try:
            lock_started = time.monotonic()
            with self.locked(task.lock):
                record['lock_wait_seconds'] = round(time.monotonic() - lock_started, 4)
                origin = None
                reuse_allowed = not self.options.get('fresh') and task.name not in self.options.get('force_tasks', [])
                if reuse_allowed and previous and previous.get('status') in ('passed', 'cached') and previous.get('fingerprint') == key:
                    origin = (Path(previous['directory']), previous['outputs'], previous['source_hash'])
                elif task.cacheable and reuse_allowed and (store / 'metadata.json').is_file():
                    try:
                        metadata = json.loads((store / 'metadata.json').read_text())
                        origin = (store / 'payload', metadata['outputs'], metadata['source_hash'])
                    except (ValueError, KeyError, TypeError):
                        origin = None
                if task.kind == 'import':
                    marker = self.root / '.godot/harness-import.json'
                    try:
                        imported = json.loads(marker.read_text()).get('fingerprint')
                    except (OSError, ValueError, TypeError):
                        imported = None
                    if imported != key: origin = None
                if origin and self.checked_copy(origin[0], origin[1], folder):
                    record.update(status='cached', origin=str(origin[0]), origin_source_hash=origin[2])
                    record['report'] = json.loads((folder / (task.report or 'suite-report.json')).read_text())
                else:
                    command = self.command(task, folder, deps)
                    record['command'] = command
                    process_started = time.monotonic()
                    output = self.process(command, folder, task)
                    record['process_seconds'] = round(time.monotonic() - process_started, 4)
                    record['report'] = self.validate(task, folder, output)
                    if self.fingerprint(task, deps, source_manifest(self.root)) != key:
                        raise RuntimeError('Task inputs changed while it ran; result will not be cached')
                    record['status'] = 'passed'
                    if task.kind == 'import':
                        (self.root / '.godot/harness-import.json').write_text(json.dumps({'fingerprint': key}))
                    if task.cacheable:
                        temporary = store.with_name(store.name + '.tmp-' + str(os.getpid()))
                        if temporary.exists(): shutil.rmtree(temporary)
                        (temporary / 'payload').mkdir(parents=True)
                        shutil.copytree(folder, temporary / 'payload', dirs_exist_ok=True)
                        (temporary / 'metadata.json').write_text(json.dumps({'outputs': file_hashes(folder), 'source_hash': self.sources['sha256']}))
                        if store.exists(): shutil.rmtree(store)
                        store.parent.mkdir(parents=True, exist_ok=True)
                        temporary.rename(store)
                if self.fingerprint(task, deps, source_manifest(self.root)) != key:
                    raise RuntimeError('Task inputs changed while resolving its result')
                record['inputs_verified'] = True
                if task.kind in ('export', 'export-fixtures'):
                    record['build_directory'] = str(folder / 'build')
                if task.kind == 'packed':
                    record['build_directory'] = next(iter(deps.values()))['build_directory']
        except InterruptedError as error:
            record.update(status='interrupted', error=str(error))
        except Exception as error:
            record.update(status='failed', error=str(error))
        if record['status'] in ('failed', 'interrupted') and (folder / 'process.log').is_file():
            # Keep the failure useful even when the large visual evidence cannot be downloaded.
            lines = (folder / 'process.log').read_text(errors='replace').splitlines()
            errors = [line for line in lines if re.search(r'error|exception|traceback|failed|no space', line, re.I)]
            record['log_excerpt'] = ('\n'.join(errors[-30:]) + '\n--- log tail ---\n' + '\n'.join(lines[-30:]))[-12000:]
        if record['status'] == 'failed' and task.kind in ('native', 'replay') and (folder / 'process.log').is_file() and not (folder / (task.report or 'suite-report.json')).is_file():
            # Native suites can print their executed counts before returning failure.
            # Preserve those counts without treating a failed process as a pass.
            try: self.validate(task, folder, (folder / 'process.log').read_text())
            except Exception: pass
        if record['status'] in ('failed', 'interrupted') and task.report and (folder / task.report).is_file():
            try:
                raw = json.loads((folder / task.report).read_text())
                record['report'] = dict(raw, failed=max(1, raw.get('failed', 0)), process_error=record.get('error'))
            except (ValueError, TypeError):
                pass
        record['seconds'] = round(time.monotonic() - started, 3)
        record['outputs'] = file_hashes(folder)
        return record
