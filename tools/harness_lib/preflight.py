"""Report the actual integration base before planning work. Never changes the checkout."""
from pathlib import Path
import subprocess


def inspect(root, fetch=False):
    root = Path(root)
    def git(*args):
        return subprocess.check_output(['git', *args], cwd=root, text=True, stderr=subprocess.DEVNULL).strip()
    if fetch: subprocess.run(['git', 'fetch', 'origin'], cwd=root, check=True)
    branch = git('branch', '--show-current') or '(detached)'
    head = git('rev-parse', 'HEAD')
    target = git('rev-parse', 'origin/main')
    ahead, behind = map(int, git('rev-list', '--left-right', '--count', 'HEAD...origin/main').split())
    return {'branch': branch, 'head': head, 'main': target, 'ahead': ahead, 'behind': behind,
            'fetch_performed': fetch, 'status': 'behind' if behind else 'current',
            'dirty_paths': len(git('status', '--porcelain=v1').splitlines()),
            'policy': 'main means the current GitHub main. Preserve its gameplay/assets/saves when adapting older refactors. Fetch once before planning; tests do not fetch in a frozen run.'}
