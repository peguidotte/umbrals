"""Conservative changed-input planning with explicit reasons and dependency closure."""
import json
from pathlib import Path
import subprocess
from .manifest import ROOT, source_manifest, matches
from .registry import registry, closure, POLICY, INFRA


def changed_paths(root=ROOT, since=None):
    if since:
        path = Path(since)
        if path.is_dir(): path = path / 'source-manifest.json'
        data = json.loads(path.read_text())
        if 'files' not in data: data = json.loads((Path(data['directory']) / 'source-manifest.json').read_text())
        current = source_manifest(root)['files']
        before = data['files']
        return sorted(name for name in set(before) | set(current) if before.get(name) != current.get(name))
    accepted = root / 'test-results/harness/accepted-source.json'
    if accepted.is_file(): return changed_paths(root, accepted)
    tracked = subprocess.run(['git', 'diff', '--name-only', 'HEAD'], cwd=root, capture_output=True, text=True, check=True).stdout.splitlines()
    untracked = subprocess.run(['git', 'ls-files', '--others', '--exclude-standard'], cwd=root, capture_output=True, text=True, check=True).stdout.splitlines()
    return sorted(set(tracked + untracked))


def plan(requested=None, changed=False, since=None, root=ROOT, tasks=None):
    tasks = tasks or registry()
    paths = changed_paths(root, since) if changed else []
    reasons = {}
    if changed:
        for name, task in tasks.items():
            hits = [path for path in paths if matches(path, task.inputs + POLICY + INFRA)]
            if hits: reasons[name] = {'reason': 'changed inputs', 'files': hits}
        propagated = True
        while propagated:
            propagated = False
            for name, task in tasks.items():
                affected = [dependency for dependency in task.deps if dependency in reasons and dependency not in task.order_only]
                if name not in reasons and affected:
                    reasons[name] = {'reason': 'changed dependency', 'affected_dependencies': affected}
                    propagated = True
        requested = list(reasons)
    else:
        requested = list(requested or [])
        reasons = {name: {'reason': 'explicit selection'} for name in requested}
    ordered = closure(tasks, requested)
    for name in ordered:
        if name not in reasons:
            reasons[name] = {'reason': 'prerequisite', 'required_by': [parent for parent in ordered if name in tasks[parent].deps]}
    return {'requested': requested, 'changed_files': paths, 'tasks': [{'name': name, 'dependencies': list(tasks[name].deps), **reasons[name]} for name in ordered],
            'complete_acceptance': False, 'policy': 'Focused plans do not waive full final verification.'}
