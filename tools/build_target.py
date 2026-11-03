"""Export a pinned output; optional fixture project is a disposable copy, never the release entry."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
from harness_io import ROOT, results_dir


def run(command, cwd=ROOT):
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=180)
    output = result.stdout + result.stderr
    print(output, end='')
    if result.returncode or 'SCRIPT ERROR:' in output or '\nERROR:' in output:
        raise RuntimeError('Godot export/import failed')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--target', choices=['Web', 'Linux', 'Windows'], default='Web')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--fixture-data', type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    project = ROOT
    if args.fixture_data:
        project = results_dir() / 'fixture-project'
        project.mkdir()
        for name in ('scripts', 'content', 'assets', 'scenes'):
            shutil.copytree(ROOT / name, project / name, ignore=shutil.ignore_patterns('*.import', '*.uid'))
        for relative in ('tests/browser/fixture_entry.gd', 'tests/browser/fixture_entry.tscn', 'tests/support/scenario_fixtures.gd'):
            destination = project / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, destination)
        shutil.copy2(args.fixture_data, project / 'tests/browser/fixtures.json')
        configuration = (ROOT / 'project.godot').read_text().replace('run/main_scene="res://scenes/main.tscn"', 'run/main_scene="res://tests/browser/fixture_entry.tscn"')
        assert 'run/main_scene="res://tests/browser/fixture_entry.tscn"' in configuration
        (project / 'project.godot').write_text(configuration)
        (project / 'export_presets.cfg').write_text((ROOT / 'export_presets.cfg').read_text().replace('tests/*,', ''))
        run(['godot', '--headless', '--path', str(project), '--editor', '--import', '--quit'])
    name = {'Web': 'index.html', 'Linux': 'Umbral.x86_64', 'Windows': 'Umbral.exe'}[args.target]
    run(['godot', '--headless', '--path', str(project), '--export-release', args.target, str(output / name)])
    if not (output / name).is_file() or (output / name).stat().st_size == 0:
        raise RuntimeError('Export produced no executable')
    if args.fixture_data:
        shutil.rmtree(project)
    report = {'suite': 'web_export', 'checks': 1, 'failed': 0, 'target': args.target,
              'fixture_build': bool(args.fixture_data), 'output': str(output)}
    (results_dir() / 'build-report.json').write_text(json.dumps(report, indent=2))
    print(json.dumps(report))


if __name__ == '__main__':
    main()
