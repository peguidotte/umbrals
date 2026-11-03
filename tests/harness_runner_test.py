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
