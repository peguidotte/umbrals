"""Scenario adapter over the current product's full routes and focused real-input tests."""
import argparse
import json
from pathlib import Path
import os
import subprocess
import sys
from browser.session import Session
from browser import integration, layout, scenarios
from harness_lib.manifest import ROOT


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--scenario', choices=['integration', 'layout', 'navigation', 'inventory', 'combat', 'rewards', 'replacement', 'persistence', 'expedition', 'title', 'cards'])
    parser.add_argument('--build-dir', type=Path, default=ROOT / 'builds/web')
    parser.add_argument('--output', type=Path, default=ROOT / 'test-results/browser')
    parser.add_argument('--video', action='store_true')
    parser.add_argument('--no-matrix', action='store_true')
    parser.add_argument('--viewport')
    parser.add_argument('--fixture')
    parser.add_argument('--large-text', action='store_true')
    args = parser.parse_args()
    combined = args.scenario is None and not args.no_matrix
    args.scenario = args.scenario or 'integration'
    args.output = args.output.resolve(); args.output.mkdir(parents=True, exist_ok=True)
    if args.scenario in ('expedition', 'title'):
        command = [sys.executable, 'tools/' + ('expedition_browser_smoke.py' if args.scenario == 'expedition' else 'title_browser_review.py'), '--build-dir', str(args.build_dir), '--output', str(args.output)]
        if args.video and args.scenario == 'title': command.append('--video')
        result = subprocess.run(command, cwd=ROOT, env=dict(os.environ, UMBRAL_RESULTS_DIR=str(args.output)))
        filename = 'browser-report.json' if args.scenario == 'expedition' else 'title-browser-report.json'
        report = json.loads((args.output / filename).read_text())
        report['captures'] = [dict(name=Path(c).stem, file=c, screen='menu') if isinstance(c, str) else c for c in report['captures']]
        report.update(suite_origin=report['suite'], suite='umbral_ui_experience', scenario=args.scenario, matrix=[], matrix_executed=False)
        (args.output / 'browser-report.json').write_text(json.dumps(report, indent=2))
        return result.returncode or int(report['failed'] != 0)
    if args.scenario == 'integration':
        env = dict(os.environ, UMBRAL_RESULTS_DIR=str(args.output))
        subprocess.run(['godot', '--headless', '--path', str(ROOT), '--script', 'tests/make_browser_plan.gd'], env=env, cwd=ROOT, check=True)
    session = Session(args)
    failure = None
    try:
        if args.scenario == 'integration':
            session.plans = json.loads((args.output / 'browser-plan.json').read_text()); integration.run(session)
        elif args.scenario == 'layout': layout.run(session)
        else: getattr(scenarios, args.scenario)(session)
        if combined:
            layout.run(session); args.scenario = 'layout'
    except Exception as error:
        failure = str(error); session.failure()
    report = session.finish(failure)
    print(json.dumps({key: report[key] for key in ['suite', 'scenario', 'checks', 'failed', 'failure', 'seconds']}))
    return int(report['failed'] != 0)


if __name__ == '__main__': raise SystemExit(main())
