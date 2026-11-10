from harness_io import results_dir
"""Compare every authored export field and a seeded run between source and an actual PCK."""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('pack', type=Path)
parser.add_argument('--fixtures', action='store_true')
args = parser.parse_args()


def snapshot(command, label, working_directory=ROOT):
    result = subprocess.run(command, cwd=working_directory, capture_output=True, text=True, timeout=45)
    output = result.stdout + result.stderr
    if result.returncode or 'SCRIPT ERROR:' in output or '\nERROR:' in output:
        raise RuntimeError(output)
    data = next(json.loads(line) for line in result.stdout.splitlines() if line.startswith('{'))
    (results_dir() / f'catalog-{label}.json').write_text(json.dumps(data, indent=2))
    return data


script = str(ROOT / 'tools/catalog_snapshot.gd')
source = snapshot(['godot', '--headless', '--path', str(ROOT), '--script', script], 'source')
# Godot can resolve excluded res:// paths from the working checkout on disk.
# An empty working directory proves all preloads/files come from the actual pack.
with tempfile.TemporaryDirectory(prefix='umbral-packed-') as directory:
    exported = snapshot(['godot', '--headless', '--main-pack', str(args.pack.resolve()), '--script', script], 'exported', directory)
comparisons = [source["catalog"] == exported["catalog"], source["initial_run"] == exported["initial_run"], *[exported[field] == args.fixtures for field in ("fixture_entry_present", "fixture_scene_present", "fixture_gallery_present", "fixture_data_present")]]
if not all(comparisons):
    raise RuntimeError('Exported catalog differs from source resources; inspect catalog-source.json and catalog-exported.json')
report = {'suite': 'packed_catalog', 'checks': len(comparisons), 'failed': 0, 'pack': str(args.pack), 'contracts': ['all authored export fields', 'seeded initial run', 'fixture entry export boundary']}
(results_dir() / 'packed-catalog-report.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report))
