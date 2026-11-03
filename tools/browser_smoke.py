"""Run one browser scenario against a pinned build. All actions use real mouse/keyboard input."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
from browser.session import Session
from browser import integration, layout, scenarios
from harness_lib.manifest import ROOT


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--scenario', choices=['navigation', 'inventory', 'combat', 'rewards', 'replacement', 'persistence', 'layout', 'integration'], default=None)
    parser.add_argument('--build-dir', type=Path, default=ROOT / 'builds/web')
    parser.add_argument('--output', type=Path, default=ROOT / 'test-results/browser')
    parser.add_argument('--video', action='store_true')
    parser.add_argument('--viewport')
    parser.add_argument('--large-text', action='store_true')
    parser.add_argument('--fixture', choices=['battle', 'wounded', 'enemy_shield', 'rewards', 'branching_rewards', 'replacement', 'inventory_full'])
    # Legacy option stays explicit; new runner owns full matrix as its own task.
    parser.add_argument('--no-matrix', action='store_true')
    args = parser.parse_args()
    legacy_matrix = args.scenario is None and not args.no_matrix
    args.scenario = args.scenario or 'integration'
    args.output.mkdir(parents=True, exist_ok=True)
    if not (args.build_dir / 'index.pck').is_file(): parser.error('Pinned Web build is missing')
    session = Session(args)
    failure = None
    try:
        if args.scenario == 'integration':
            env = dict(os.environ, UMBRAL_RESULTS_DIR=str(args.output.resolve()))
            process = subprocess.run(['godot', '--headless', '--path', str(ROOT), '--script', 'tests/make_browser_plan.gd'], cwd=ROOT, env=env, capture_output=True, text=True, timeout=60)
            output = process.stdout + process.stderr
            if process.returncode or 'SCRIPT ERROR:' in output or '\nERROR:' in output: raise RuntimeError(output)
            session.plans = json.loads((args.output / 'browser-plan.json').read_text())
            integration.run(session)
            if legacy_matrix:
                layout.run(session)
                args.scenario = "layout"
        elif args.scenario == 'layout':
            layout.run(session)
        else:
            getattr(scenarios, args.scenario)(session)
    except Exception as error:
        failure = str(error)
        session.failure()
    report = session.finish(failure)
    print(json.dumps({key: report[key] for key in ['suite', 'scenario', 'checks', 'failed', 'failure', 'seconds']}))
    return int(bool(report['failed']))


if __name__ == '__main__':
    raise SystemExit(main())
