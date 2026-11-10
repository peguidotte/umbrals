"""Export a pinned output; optional fixture project is a disposable copy, never the release entry."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
from harness_io import ROOT, results_dir


def fixture_configuration(configuration):
    """Build the disposable boot config with serialized resource imports."""
    production_scene = 'run/main_scene="res://scenes/main.tscn"'
    fixture_scene = 'run/main_scene="res://tests/browser/fixture_entry.tscn"'
    if configuration.count(production_scene) != 1:
        raise ValueError('Expected one production main scene')
    configuration = configuration.replace(production_scene, fixture_scene)
    # A CI cold import aborted in Godot's font import. Serialization is a bounded
    # experiment; the abort alone does not prove concurrent imports caused it.
    editor = re.search(r'(?m)^\[editor\]\s*$', configuration)
    if not editor:
        return configuration.rstrip() + '\n\n[editor]\nimport/use_multiple_threads=false\n'
    start = editor.end()
    next_section = re.search(r'(?m)^\[', configuration[start:])
    end = start + next_section.start() if next_section else len(configuration)
    section = configuration[start:end]
    section = re.sub(r'(?m)^\s*import/use_multiple_threads\s*=.*$', '', section)
    return configuration[:start] + '\nimport/use_multiple_threads=false\n' + section.lstrip('\n') + configuration[end:]


def run(command, cwd=ROOT, timeout=180):
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=timeout)
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
    from card_asset_pipeline import export_gate
    # Only a deliberately pinned new presentation enables its strict catalog gate.
    # The legacy build remains available while artwork is pending review.
    export_gate(ROOT)
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    project = ROOT
    if args.fixture_data:
        project = results_dir() / 'fixture-project'
        project.mkdir()
        for name in ('scripts', 'content', 'assets', 'scenes'):
            if not (ROOT / name).is_dir(): continue
            shutil.copytree(ROOT / name, project / name, ignore=shutil.ignore_patterns('*.import', '*.uid'))
        for relative in ('tests/browser/fixture_entry.gd', 'tests/browser/fixture_entry.tscn', 'tests/browser/card_gallery.gd'):
            destination = project / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, destination)
        shutil.copy2(args.fixture_data, project / 'tests/browser/fixtures.json')
        configuration = fixture_configuration((ROOT / 'project.godot').read_text())
        (project / 'project.godot').write_text(configuration)
        (project / 'export_presets.cfg').write_text((ROOT / 'export_presets.cfg').read_text().replace('tests/*,', '').replace('include_filter="assets/', 'include_filter="tests/browser/fixtures.json,assets/'))
        run(['godot', '--headless', '--path', str(project), '--editor', '--import', '--quit'], timeout=480)
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
