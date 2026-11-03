from harness_io import results_dir
"""Exercise scaffold/refusal/registration in an isolated project; never write real content."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
checks = 0


def expect(condition):
    global checks
    checks += 1
    if not condition:
        raise AssertionError('Authoring contract failed')



def run(folder, *arguments, expected=0):
    result = subprocess.run(['godot', '--headless', '--path', str(folder), '--script', *arguments], capture_output=True, text=True, timeout=45, env={**os.environ, "UMBRAL_RESULTS_DIR": str(folder / "test-results")})
    output = result.stdout + result.stderr
    if result.returncode != expected or 'SCRIPT ERROR:' in output or '\nERROR:' in output:
        raise RuntimeError(output)
    return output


with tempfile.TemporaryDirectory(prefix='umbral-authoring-') as temporary:
    folder = Path(temporary)
    for name in ['scripts', 'content', 'assets']:
        shutil.copytree(ROOT / name, folder / name, ignore=shutil.ignore_patterns('*.import', '*.uid', '__pycache__'))
    (folder / 'tools').mkdir()
    (folder / 'test-results').mkdir()
    for name in ['author_umbral.gd', 'content_checks.gd', 'package_validation.gd']:
        shutil.copy2(ROOT / 'tools' / name, folder / 'tools' / name)
    (folder / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Isolated authoring smoke"\n')
    manifest_before = (folder / 'content/catalog.tres').read_bytes()
    run(folder, 'res://tools/author_umbral.gd', '--', '--id', 'fixture', '--forms', 'young,middle,final')
    package = folder / 'content/umbrals/fixture'
    expected_files = ['species.tres', 'provenance.json', 'mechanics/trait.gd', 'forms/young/form.tres', 'forms/middle/form.tres', 'forms/final/form.tres']
    expect(all((package / name).is_file() for name in expected_files))
    # Refusal is safe: neither the manifest nor the readiness flag may be written.
    result = run(folder, 'res://tools/author_umbral.gd', '--', '--operation', 'register', '--id', 'fixture', expected=1)
    expect('Missing content asset' in result and 'pure trait contract' in result)
    expect((folder / 'content/catalog.tres').read_bytes() == manifest_before)
    expect('ready_for_play = true' not in (package / 'species.tres').read_text())
    run(folder, 'res://tools/author_umbral.gd', '--', '--id', 'fixture', '--forms', 'young', expected=2)
    # Supply real SVG bytes and provenance, then complete metadata in the isolated Resources.
    sample = folder / 'content/umbrals/ember/forms/ember/portrait.svg'
    copied = []
    for relative in ['powers/core.svg'] + [f'forms/{name}/portrait_{side}.svg' for name in ['young', 'middle', 'final'] for side in ['left', 'right']]:
        path = package / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(sample, path)
        copied.append({'path': str(path.relative_to(folder)), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'source': {'kind': 'isolated test fixture', 'original': 'original project SVG'}})
    manifest = json.loads((folder / 'assets/asset-manifest.json').read_text())
    manifest['assets'].extend(copied)
    (folder / 'assets/asset-manifest.json').write_text(json.dumps(manifest))
    (package / 'provenance.json').write_text(json.dumps({'species_id': 'fixture', 'assets': copied}))
    (package / 'mechanics/trait.gd').write_text('extends "res://scripts/domain/trait_behavior.gd"\nfunc is_implemented() -> bool:\n\treturn true\n')
    (folder / 'complete.gd').write_text('''extends SceneTree
func _init() -> void:
	var species = load("res://content/umbrals/fixture/species.tres")
	species.element = "Fixture"
	species.description = "Fixture species"
	species.trait_name = "Neutral fixture trait"
	species.trait_description = "Fixture strength %d"
	for shape in species.forms:
		shape.description = "Fixture form"
		for facing in ["left", "right"]:
			var direction = shape.presentation.direction(facing)
			direction.portrait_path = direction.portrait_path.replace(".png", ".svg")
			assert(ResourceSaver.save(direction, direction.resource_path) == OK)
		for power in shape.powers:
			power.name = "Fixture power"
			power.identity.description = "Fixture intent"
			power.art_path = power.art_path.replace(".png", ".svg")
			assert(ResourceSaver.save(power.identity, power.identity.resource_path) == OK)
			assert(ResourceSaver.save(power, power.resource_path) == OK)
		assert(ResourceSaver.save(shape, shape.resource_path) == OK)
	assert(ResourceSaver.save(species, species.resource_path) == OK)
	quit()
''')
    run(folder, 'res://complete.gd')
    result = run(folder, 'res://tools/author_umbral.gd', '--', '--operation', 'register', '--id', 'fixture')
    expect('"position":3' in result)
    run(folder, 'res://tools/content_checks.gd')
    report = json.loads((folder / 'test-results/content-report.json').read_text())
    expect(report['species'] == 4 and report['forms'] == 9 and report['failed'] == 0)
report = {'suite': 'authoring_smoke', 'checks': checks, 'failed': 0, 'cases': ['three-form scaffold', 'complete package structure', 'missing art/trait refusal', 'manifest preserved on refusal', 'draft flag preserved', 'overwrite refusal', 'authored assets/provenance', 'append-only registration', 'four species and nine forms validated', 'isolated project only']}
(results_dir() / 'authoring-report.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report))
