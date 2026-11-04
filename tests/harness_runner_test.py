"""Behavioral tests of scheduling, filtering, cache validation, isolation and interruption."""
import builtins
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import symtable
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from harness_lib.manifest import source_manifest, file_hashes
from harness_lib.registry import Task, FULL, registry, closure, coverage
from harness_lib.runner import run
from harness_lib.planning import plan
from harness_lib.executor import Executor
from harness_io import results_dir


class NativePython(Executor):
    def command(self, task, folder, deps):
        return [sys.executable, str(self.root / task.script)]


class Contracts(unittest.TestCase):
    def test_parallel_ci_rejects_incomplete_mixed_and_tampered_results(self):
        from datetime import datetime, timezone
        from unittest.mock import patch
        import base64
        import zipfile
        import ci_parallel as ci
        from harness_lib.registry import SCENARIOS
        root = self.root
        prepared = root / 'prepared'
        prepared.mkdir()
        sources = source_manifest()
        (prepared / 'source-manifest.json').write_text(json.dumps(sources))
        tasks = registry()
        prep_tasks = {}
        for name in closure(tasks, ci.PREPARE):
            task_dir = prepared / 'tasks' / name
            task_dir.mkdir(parents=True)
            task = tasks[name]
            report = {'suite': task.suite, 'checks': 1, 'failed': 0}
            if task.report:
                (task_dir / task.report).write_text(json.dumps(report))
            record = {'name': name, 'status': 'passed', 'inputs_verified': True, 'directory': str(task_dir),
                      'outputs': file_hashes(task_dir), 'report': report}
            if name in ('web', 'web-fixtures'):
                (task_dir / 'build').mkdir()
                record['build_directory'] = str(task_dir / 'build')
            if name in ('packed-catalog', 'packed-fixtures'):
                record['build_directory'] = prep_tasks['web' if name == 'packed-catalog' else 'web-fixtures']['build_directory']
            prep_tasks[name] = record
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
        prep = {'status': 'passed', 'source_hash': sources['sha256'], 'final_source_hash': sources['sha256'],
                'source_unchanged': True, 'tools': {'godot': '4.6.3'}, 'ci_identity': ci.identity(),
                'directory': str(prepared), 'requested': list(ci.PREPARE), 'started_utc': stamp, 'tasks': prep_tasks}
        (prepared / 'harness-run.json').write_text(json.dumps(prep))
        viewports = json.loads((ROOT / 'docs/ux-contracts.json').read_text())['viewports']
        png = base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/a4kAAAAASUVORK5CYII=')
        folders = []
        for group, scenarios in ci.GROUPS.items():
            folder = root / group
            folder.mkdir()
            records = {}
            for scenario in scenarios:
                name = 'browser.' + scenario
                task_dir = folder / 'tasks' / name
                task_dir.mkdir(parents=True)
                report = {'suite': 'umbral_ui_experience', 'scenario': scenario, 'checks': 1, 'failed': 0, 'captures': [], 'seconds': 1}
                if scenario == 'layout':
                    report.update(matrix_executed=True, matrix=[{'viewport': {'width': w, 'height': h}, 'status': 'passed'} for w, h in viewports])
                if scenario == 'integration':
                    (task_dir / 'gameplay.webm').write_bytes(b'video')
                    (task_dir / 'sample.png').write_bytes(png)
                    report['captures'].append({'name': 'sample', 'file': 'sample.png', 'screen': 'battle'})
                (task_dir / 'browser-report.json').write_text(json.dumps(report))
                records[name] = {'name': name, 'status': 'passed', 'inputs_verified': True, 'directory': str(task_dir),
                                 'outputs': file_hashes(task_dir), 'report': report,
                                 'arguments': {'viewport': None, 'large_text': None, 'fixture': None, 'video': True}}
            shard = {'directory': str(folder), 'group': group, 'status': 'passed', 'source_unchanged': True,
                     'source_hash': sources['sha256'], 'final_source_hash': sources['sha256'], 'tools': prep['tools'],
                     'ci_identity': prep['ci_identity'], 'preparation_digest': ci.preparation_digest(prep), 'tasks': records}
            (folder / 'shard.json').write_text(json.dumps(shard))
            folders.append(folder)
        self.assertEqual(sum(map(len, ci.GROUPS.values())), len(SCENARIOS))
        def rejected(paths=folders):
            with self.assertRaises((ValueError, OSError, KeyError)):
                ci.aggregate(prepared, paths, root / 'result', root / 'ci-run.json')
        rejected(folders[:-1])
        rejected(folders[:-1] + [folders[0]])
        path = folders[0] / 'shard.json'
        original = path.read_text()
        for field, value in [('source_hash', 'old'), ('tools', {'godot': 'old'}),
                             ('preparation_digest', 'other'), ('ci_identity', {'commit': 'old'}), ('status', 'failed')]:
            changed = json.loads(original); changed[field] = value
            path.write_text(json.dumps(changed)); rejected()
        changed = json.loads(original); changed['tasks'].clear()
        path.write_text(json.dumps(changed)); rejected()
        path.write_text(original)
        output = folders[0] / 'tasks/browser.integration/gameplay.webm'
        output.write_bytes(b'tampered'); rejected(); output.write_bytes(b'video')
        manifest = prepared / 'source-manifest.json'
        original_manifest = manifest.read_text()
        manifest.write_text('{}'); rejected(); manifest.write_text(original_manifest)
        with patch('harness_lib.builds.publish_build'):
            ci.aggregate(prepared, folders, root / 'result', root / 'ci-run.json')
        combined = json.loads((root / 'ci-run.json').read_text())
        self.assertTrue(combined['coverage']['complete'])
        self.assertEqual({name[8:] for name in combined['tasks'] if name.startswith('browser.')}, set(SCENARIOS))
        self.assertEqual(json.loads((root / 'result/source-manifest.json').read_text()), sources)
        html = (root / 'result/review-standalone.html').read_text()
        self.assertIn('data:image/png;base64,', html)
        self.assertIn('download="source-manifest.json"', html)
        with zipfile.ZipFile(root / 'result/review-bundle.zip') as bundle:
            self.assertIsNone(bundle.testzip())
            self.assertTrue({'index.html', 'source-manifest.json', 'browser/gameplay.webm', 'browser/integration/sample.png'} <= set(bundle.namelist()))

    def test_parallel_ci_checks_prepared_outputs(self):
        from unittest.mock import patch
        import ci_parallel as ci
        from harness_lib.registry import Task
        folder = self.root / 'prepared'
        task_dir = folder / 'tasks/example'
        task_dir.mkdir(parents=True)
        (task_dir / 'suite.json').write_text(json.dumps({'checks': 1, 'failed': 0}))
        record = {'name': 'example', 'status': 'passed', 'inputs_verified': True,
                  'directory': str(task_dir), 'outputs': file_hashes(task_dir), 'report': {'checks': 1, 'failed': 0}}
        report = {'status': 'passed', 'source_unchanged': True, 'source_hash': 'abc', 'final_source_hash': 'abc',
                  'requested': ['example'], 'tasks': {'example': record}}
        with patch.object(ci, 'registry', return_value={'example': Task('example', 'python', report='suite.json')}):
            ci.verify_run(report, folder, ['example'], 'abc')
            (task_dir / 'suite.json').write_text('tampered')
            with self.assertRaisesRegex(ValueError, 'Tampered'):
                ci.verify_run(report, folder, ['example'], 'abc')

    def test_recovery_reads_compact_and_legacy_diagnostics(self):
        import textwrap
        import zipfile
        workflow = (ROOT / '.github/workflows/recover-diagnostics.yml').read_text()
        script = textwrap.dedent(workflow.split("          python - <<'PY'\n", 1)[1].split('          PY\n', 1)[0])
        cases = {
            'ci-diagnostics.json': json.dumps({'tasks': {'web-fixtures': {'status': 'failed', 'log_excerpt': 'native import aborted'}}}),
            'run/tasks/web-fixtures/process.log': 'display.ttf\nfree(): invalid size\n',
        }
        for name, contents in cases.items():
            with tempfile.TemporaryDirectory(prefix='umbral-recovery-test-') as folder:
                with zipfile.ZipFile(Path(folder) / 'evidence.zip', 'w') as archive:
                    archive.writestr(name, contents)
                env = dict(os.environ, RUNNER_TEMP=folder, TASK_NAME='web-fixtures')
                result = subprocess.run([sys.executable, '-c', script], env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn('native import aborted' if name.endswith('.json') else 'free(): invalid size', result.stdout)

    def test_fixture_configuration_serializes_only_disposable_project(self):
        from build_target import fixture_configuration
        production = (ROOT / 'project.godot').read_text()
        fixture = fixture_configuration(production)
        self.assertIn('run/main_scene="res://tests/browser/fixture_entry.tscn"', fixture)
        self.assertIn('[editor]\nimport/use_multiple_threads=false', fixture)
        self.assertNotIn('import/use_multiple_threads=false', production)
        edited = fixture_configuration(production + '\n[editor]\nimport/use_multiple_threads=true\n')
        self.assertEqual(edited.count('import/use_multiple_threads='), 1)
        self.assertIn('import/use_multiple_threads=false', edited)

    def test_browser_modules_have_bound_global_references(self):
        # Importing Playwright is not required by the headless job. Inspect Python's
        # own symbol table, including nested callbacks, before starting a browser.
        def missing(source, filename):
            module = symtable.symtable(source, filename, 'exec')
            known = set(vars(builtins)) | {'__file__', '__name__', '__package__', '__builtins__'}
            known.update(symbol.get_name() for symbol in module.get_symbols() if symbol.is_assigned() or symbol.is_imported())
            absent = set()
            def visit(table):
                for symbol in table.get_symbols():
                    if symbol.is_global() and symbol.is_referenced() and symbol.get_name() not in known:
                        absent.add(symbol.get_name())
                for child in table.get_children(): visit(child)
            visit(module)
            return absent
        for path in (ROOT / 'tools/browser').rglob('*.py'):
            self.assertEqual(missing(path.read_text(), str(path)), set(), str(path))
        source = (ROOT / 'tools/browser/integration.py').read_text().replace('import math\n', '')
        self.assertIn('math', missing(source, 'integration-without-math.py'))

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='umbral-harness-contract-')
        self.root = Path(self.temporary.name)
        self.script('ok', 1)

    def tearDown(self):
        self.temporary.cleanup()

    def script(self, name, count, extra=''):
        (self.root / (name + '.py')).write_text('''import os,json,time
from pathlib import Path
folder=Path(os.environ['UMBRAL_RESULTS_DIR'])
''' + extra + f"\nreport={{'suite':'fake','checks':{count},'failed':0}}\n(folder/'suite.json').write_text(json.dumps(report))\nprint(json.dumps(report),flush=True)\n")
        return Task(name, 'python', script=name + '.py', inputs=(name + '.py',), suite='fake', report='suite.json', cacheable=True, lock='cache-' + name)

    def execute(self, tasks, names=None, options=None, cls=Executor):
        return run(names or list(tasks), options or {}, root=self.root, tasks=tasks, executor_type=cls)

    def test_legacy_fixture_change_selects_save_suite_without_browser(self):
        from unittest.mock import patch
        with patch('harness_lib.planning.changed_paths', return_value=['tests/fixtures/expedition_schema1_44943dc.json']):
            result = plan(changed=True)
        self.assertIn('expedition-save', result['requested'])
        self.assertNotIn('browser.integration', result['requested'])

    def test_registry_is_acyclic_and_every_suite_has_one_owner(self):
        tasks = registry()
        self.assertEqual(len(closure(tasks, tasks)), len(tasks))
        self.assertIn('natures_and_reactions', tasks['rules'].cases)
        self.assertEqual(tasks['expedition-save'].minimum, 24)

    def test_preflight_detects_a_diverged_main(self):
        from harness_lib.preflight import inspect
        def git(*args):
            return subprocess.check_output(['git', *args], cwd=self.root, text=True, stderr=subprocess.DEVNULL).strip()
        git('init', '--initial-branch=main'); git('config', 'user.name', 'Harness test'); git('config', 'user.email', 'test@example.invalid')
        git('add', '.'); git('commit', '-m', 'base'); base = git('rev-parse', 'HEAD')
        git('checkout', '-b', 'work'); (self.root / 'change').touch(); git('add', '.'); git('commit', '-m', 'work')
        remote = subprocess.check_output(['git', 'commit-tree', 'HEAD^{tree}', '-p', base, '-m', 'remote'], cwd=self.root, text=True).strip()
        git('update-ref', 'refs/remotes/origin/main', remote)
        report = inspect(self.root)
        self.assertEqual((report['ahead'], report['behind'], report['status']), (1, 1, 'behind'))
        self.assertFalse(report['fetch_performed'])

    def test_serial_locks_do_not_fill_workers_with_waiters(self):
        gate = self.root / 'released'
        first = self.script('first', 1, "deadline=time.monotonic()+3\nwhile not Path(" + repr(str(gate)) + ").exists() and time.monotonic()<deadline:time.sleep(.01)\nassert Path(" + repr(str(gate)) + ").exists()")
        second = self.script('second', 1)
        release = self.script('release', 1, "Path(" + repr(str(gate)) + ").touch()")
        from dataclasses import replace
        tasks = {'first': replace(first, lock='shared'), 'second': replace(second, lock='shared'), 'release': release}
        self.assertEqual(self.execute(tasks, options={'jobs': 2})['status'], 'passed')

    def test_failed_native_process_keeps_executed_counts(self):
        (self.root / 'broken.py').write_text("import json\nprint(json.dumps({'suite':'fake','checks':3,'failed':2}))\nraise SystemExit(1)\n")
        task = Task('broken', 'native', script='broken.py', inputs=('broken.py',), suite='fake', report='suite-report.json')
        report = self.execute({'broken': task}, cls=NativePython)['tasks']['broken']
        self.assertEqual(report['status'], 'failed')
        self.assertEqual((report['report']['checks'], report['report']['failed']), (3, 2))

    def test_cycles_and_missing_dependencies_fail(self):
        with self.assertRaises(ValueError): closure({'a': Task('a', 'python', ('a',))}, ['a'])
        with self.assertRaises(ValueError): closure({}, ['missing'])

    def test_full_rejects_partial_filters(self):
        for key, value in [('case', 'traits'), ('viewport', '1280x720'), ('fixture', 'battle')]:
            with self.assertRaises(ValueError):
                run([], {'full': True, key: value}, root=self.root)

    def test_case_registry_matches_gdscript_dispatch(self):
        import re
        for name, task in registry().items():
            if task.cases:
                script = (ROOT / task.script).read_text()
                declared = re.findall(r'"([a-z_]+)": test_\w+', script)
                self.assertEqual(set(task.cases), set(declared), name)

    def test_focused_cannot_be_complete(self):
        records = {name: {'status': 'passed'} for name in FULL}
        self.assertFalse(coverage(records, FULL)['complete'])
        self.assertTrue(coverage(records, FULL, True)['complete'])
        records['rules']['status'] = 'cached'
        self.assertFalse(coverage(records, FULL, True)['complete'])
        records['rules']['status'] = 'passed'
        records['browser.layout']['status'] = 'skipped'
        self.assertFalse(coverage(records, FULL, True)['complete'])

    def test_cache_hit_and_input_change(self):
        task = self.script('ok', 1)
        first = self.execute({'ok': task})
        second = self.execute({'ok': task})
        self.assertEqual(second['tasks']['ok']['status'], 'cached')
        self.assertNotEqual(first['directory'], second['directory'])
        self.script('ok', 2)
        third = self.execute({'ok': task})
        self.assertEqual(third['tasks']['ok']['status'], 'passed')
        self.assertEqual(third['tasks']['ok']['report']['checks'], 2)

    def test_corrupt_output_is_rebuilt(self):
        task = self.script('ok', 1)
        first = self.execute({'ok': task})
        store = self.root / 'test-results/harness/cache/ok' / first['tasks']['ok']['fingerprint'] / 'payload'
        (store / 'suite.json').write_text('{"suite":"fake","checks":999,"failed":0}')
        second = self.execute({'ok': task})
        self.assertEqual(second['tasks']['ok']['status'], 'passed')
        self.assertEqual(second['tasks']['ok']['report']['checks'], 1)

    def test_empty_suite_fails_and_blocks_dependents(self):
        task = self.script('empty', 0)
        child = Task('child', 'python', ('empty',), script='ok.py', suite='fake', report='suite.json')
        report = self.execute({'empty': task, 'child': child})
        self.assertEqual(report['status'], 'failed')
        self.assertEqual(report['tasks']['child']['status'], 'skipped')

    def test_resume_rechecks_changed_inputs(self):
        a, b = self.script('a', 1), self.script('b', 0)
        first = self.execute({'a': a, 'b': b})
        self.script('b', 2)
        second = self.execute({'a': a, 'b': b}, options={'resume': str(Path(first['directory']) / 'harness-run.json')})
        self.assertEqual(second['tasks']['a']['status'], 'cached')
        self.assertEqual(second['tasks']['b']['status'], 'passed')
        self.assertEqual(second['status'], 'passed')
        self.assertFalse(second['coverage']['complete'])

    def test_forced_task_reruns_with_verified_dependency(self):
        from dataclasses import replace
        parent = self.script('parent', 1)
        child = replace(self.script('child', 1), deps=('parent',))
        tasks = {'parent': parent, 'child': child}
        first = self.execute(tasks)
        second = self.execute(tasks, names=['child'], options={
            'resume': str(Path(first['directory']) / 'harness-run.json'), 'force_tasks': ['child']})
        self.assertEqual(second['tasks']['parent']['status'], 'cached')
        self.assertEqual(second['tasks']['child']['status'], 'passed')
        self.assertFalse(second['coverage']['complete'])

    def test_failure_excerpt_includes_error_outside_tail(self):
        import contextlib
        import io
        (self.root / 'broken.py').write_text("print('ERROR: specific cause')\nprint('noise\\n' * 80)\nraise SystemExit(1)\n")
        task = Task('broken', 'python', script='broken.py', inputs=('broken.py',), suite='fake', report='suite.json')
        # This is an intentionally failing child. Keep its diagnostic in the
        # assertion scope so the outer harness does not see a real engine error.
        with contextlib.redirect_stdout(io.StringIO()) as captured:
            record = self.execute({'broken': task})['tasks']['broken']
        self.assertEqual(record['status'], 'failed')
        self.assertIn('ERROR: specific cause', record['log_excerpt'])
        self.assertIn('ERROR: specific cause', captured.getvalue())

    def test_changed_planning_explains_dependencies(self):
        task = self.script('ok', 1)
        before = self.root / 'before.json'
        before.write_text(json.dumps(source_manifest(self.root)))
        self.script('ok', 2)
        tasks = {'ok': task, 'child': Task('child', 'python', ('ok',), inputs=('unrelated',))}
        result = plan(changed=True, since=before, root=self.root, tasks=tasks)
        self.assertIn('ok', result['requested'])
        self.assertIn('child', result['requested'])
        self.assertEqual(next(task for task in result['tasks'] if task['name']=='child')['reason'], 'changed dependency')
        self.assertEqual(result['tasks'][0]['reason'], 'changed inputs')
        self.assertIn('ok.py', result['tasks'][0]['files'])

    def test_native_userdata_is_per_execution(self):
        (self.root / 'native.py').write_text("import os,json\nfrom pathlib import Path\nr={'suite':'fake','checks':1,'failed':0,'data':os.environ['XDG_DATA_HOME']}\nprint(json.dumps(r))\n")
        task = Task('native', 'native', script='native.py', inputs=('native.py',), suite='fake', report='suite-report.json')
        first = self.execute({'native': task}, cls=NativePython)
        second = self.execute({'native': task}, cls=NativePython)
        self.assertNotEqual(first['tasks']['native']['report']['data'], second['tasks']['native']['report']['data'])
        self.assertTrue(first['tasks']['native']['report']['data'].startswith(first['directory']))

    def test_case_report_must_match_exclusive_filter(self):
        (self.root / 'native.py').write_text("import json\nprint(json.dumps({'suite':'fake','checks':1,'failed':0,'case':'other','cases':['other']}))\n")
        task = Task('native', 'native', script='native.py', suite='fake', report='suite-report.json', inputs=('native.py',))
        report = self.execute({'native': task}, options={'case_task': 'native', 'case': 'wanted'}, cls=NativePython)
        self.assertEqual(report['status'], 'failed')
        self.assertIn('exclusively', report['tasks']['native']['error'])

    def test_independent_tasks_really_overlap(self):
        tasks = {}
        for name, other in [('a', 'b'), ('b', 'a')]:
            extra = f'''gate=Path('test-results');gate.mkdir(exist_ok=True)
(gate/'{name}').touch()
deadline=time.monotonic()+5
while not (gate/'{other}').exists() and time.monotonic()<deadline:time.sleep(.01)
assert (gate/'{other}').exists(), 'independent tasks did not overlap'
'''
            tasks[name] = self.script(name, 1, extra)
        result = self.execute(tasks, options={'jobs': 2})
        self.assertEqual(result['status'], 'passed')

    def test_source_change_invalidates_result_and_cache(self):
        task = self.script('changed', 1, "Path(__file__).write_text('changed while running')\n")
        result = self.execute({'changed': task})
        self.assertEqual(result['status'], 'failed')
        self.assertFalse(result['source_unchanged'])
        self.assertFalse((self.root / 'test-results/harness/cache/changed').exists())

    def test_unrelated_changes_keep_focused_input_evidence(self):
        task = self.script('unrelated', 1, "Path('README.md').write_text('documentation change')\n")
        result = self.execute({'unrelated': task})
        self.assertEqual(result['status'], 'passed')
        self.assertFalse(result['source_unchanged'])
        self.assertTrue(result['inputs_verified'])
        self.assertFalse(result['coverage']['complete'])

    def test_full_source_change_cannot_be_complete(self):
        normal = self.script('normal', 1)
        changed = self.script('doc', 1, "Path('README.md').write_text('changed during acceptance')\n")
        tasks = {name: Task(name, 'python', script=changed.script if name == 'architecture' else normal.script,
                            suite='fake', report='suite.json', inputs=(changed.script, normal.script)) for name in FULL}
        result = self.execute(tasks, options={'full': True, 'jobs': 8})
        self.assertEqual(result['status'], 'failed')
        self.assertFalse(result['coverage']['complete'])
        self.assertFalse(result['source_unchanged'])

    def test_unknown_case_rejected_before_execution(self):
        result = subprocess.run([sys.executable, str(ROOT / 'tools/harness.py'), 'check', '--suite', 'rules', '--case', 'missing'], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn('compatible suite', result.stderr)

    def test_interruption_is_durable_and_not_passed(self):
        self.script('slow', 1, "print('READY',flush=True)\ntime.sleep(30)\n")
        child = f'''import sys,json
from pathlib import Path
sys.path.insert(0,{str(ROOT / 'tools')!r})
from harness_lib.runner import run
from harness_lib.registry import Task
root=Path({str(self.root)!r})
tasks={{'slow':Task('slow','python',script='slow.py',suite='fake',report='suite.json',inputs=('slow.py',)),'later':Task('later','python',('slow',),script='ok.py')}}
r=run(['later'],root=root,tasks=tasks,output=root/'artifacts/interrupted')
print(r['status'])
'''
        process = subprocess.Popen([sys.executable, '-c', child], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        log = self.root / 'artifacts/interrupted/tasks/slow/process.log'
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            if log.is_file() and 'READY' in log.read_text(): break
            time.sleep(.05)
        process.send_signal(signal.SIGTERM)
        stdout, stderr = process.communicate(timeout=10)
        self.assertEqual(process.returncode, 0, stdout + stderr)
        result = json.loads((self.root / 'artifacts/interrupted/harness-run.json').read_text())
        self.assertEqual(result['status'], 'interrupted')
        self.assertEqual(result['tasks']['slow']['status'], 'interrupted')
        self.assertEqual(result['tasks']['later']['status'], 'skipped')
        self.assertFalse(result['coverage']['complete'])


if __name__ == '__main__':
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(Contracts)
    result = unittest.TextTestRunner(verbosity=1).run(suite)
    report = {'suite': 'harness_runner', 'checks': result.testsRun, 'failed': len(result.failures) + len(result.errors)}
    (results_dir() / 'harness-report.json').write_text(json.dumps(report, indent=2))
    print(json.dumps(report))
    raise SystemExit(0 if result.wasSuccessful() else 1)
