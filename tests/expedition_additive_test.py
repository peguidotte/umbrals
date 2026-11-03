#!/usr/bin/env python3
"""Exercise actual authored catalog additions in a disposable Godot project."""
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def add_entry(path, resource, entry_id, field):
    text = path.read_text()
    text = re.sub(r'load_steps=(\d+)', lambda m: f'load_steps={int(m[1]) + 1}', text, count=1)
    text = text.replace('\n[resource]', f'\n[ext_resource type="Resource" path="res://{resource}" id="{entry_id}"]\n\n[resource]')
    text = text.replace('])\n', f', ExtResource("{entry_id}")])\n')
    path.write_text(text)

def main():
    with tempfile.TemporaryDirectory(prefix='umbral-additive-') as tmp:
        project = Path(tmp)
        for directory in ('scripts', 'content'):
            shutil.copytree(ROOT / directory, project / directory)
        (project / 'tests/fixtures').mkdir(parents=True)
        for file in ('expedition_additive_test.gd', 'fixtures/expedition_schema2_6e1b2ed.json'):
            shutil.copy2(ROOT / 'tests' / file, project / 'tests' / file)
        shutil.copy2(ROOT / 'project.godot', project / 'project.godot')
        species = project / 'content/species/future_species'
        species.mkdir()
        (species / 'species.tres').write_text((project / 'content/species/ember/species.tres').read_text().replace('id = "ember"', 'id = "future_species"', 1))
        add_entry(project / 'content/species/catalog.tres', 'content/species/future_species/species.tres', 'future', 'species')
        power = (project / 'content/powers/fireball.tres').read_text().replace('id = "fireball"', 'id = "future_power"', 1)
        (project / 'content/powers/future_power.tres').write_text(power)
        add_entry(project / 'content/powers/catalog.tres', 'content/powers/future_power.tres', 'future', 'entries')
        item = (project / 'content/items/potion.tres').read_text().replace('id = "potion"', 'id = "future_item"', 1)
        (project / 'content/items/future_item.tres').write_text(item)
        add_entry(project / 'content/items/catalog.tres', 'content/items/future_item.tres', 'future', 'entries')
        command = ['godot', '--headless', '--path', str(project), '--script', 'res://tests/expedition_additive_test.gd']
        def run(extra=()):
            result = subprocess.run(command + list(extra), text=True, capture_output=True, timeout=60)
            print(result.stdout, end='')
            print(result.stderr, end='')
            return result.returncode
        failures = run()
        cases = [
            ('content/species/ember/species.tres', '"max_hp": 40', '"max_hp": 41'),
            ('scripts/content.gd', '"ember": ["moss", "dew"]', '"ember": ["dew", "moss"]'),
            ('content/species/catalog.tres', 'ExtResource("2"), ExtResource("3")', 'ExtResource("3"), ExtResource("2")'),
            ('content/items/potion.tres', 'effect_id = "heal"', 'effect_id = "revive"'),
        ]
        for name, before, after in cases:
            path = project / name
            original = path.read_text()
            assert before in original
            path.write_text(original.replace(before, after, 1))
            failures += run(('--', '--reject'))
            path.write_text(original)
        return bool(failures)

if __name__ == '__main__':
    raise SystemExit(main())
