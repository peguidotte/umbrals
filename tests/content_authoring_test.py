#!/usr/bin/env python3
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ContentAuthoringTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.addCleanup(self.temporary.cleanup)
        shutil.copytree(ROOT / 'content', self.root / 'content')
        for relative in ('assets/runtime-lock.json', 'scripts/battle/item_effects/registry.gd', 'tools/content_authoring.py'):
            dest = self.root / relative
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, dest)

    def run_cli(self, *args, success=True):
        result = subprocess.run([sys.executable, str(self.root / 'tools/content_authoring.py'), *args], text=True, capture_output=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def test_cli_authors_each_domain(self):
        for domain, new_id, fallback in [('powers', 'spark', 'fireball'), ('items', 'herb', 'potion'), ('encounters', 'grove', 'clearing')]:
            self.run_cli('author', domain, new_id, '--fallback', fallback)
            text = (self.root / 'content' / domain / (new_id + '.tres')).read_text()
            self.assertIn('id = ' + json.dumps(new_id), text)
            self.assertIn('/' + new_id + '.tres', (self.root / 'content' / domain / 'catalog.tres').read_text())
        self.run_cli('validate')
        self.run_cli('author', 'items', 'herb', '--fallback', 'potion', success=False)

    def test_unknown_effect_and_enemy_references_rejected(self):
        self.run_cli('author', 'items', 'herb', '--fallback', 'potion')
        path = self.root / 'content/items/herb.tres'
        path.write_text(path.read_text().replace('effect_id = "heal"', 'effect_id = "unknown"'))
        self.assertIn('unknown item effect', self.run_cli('validate', success=False).stderr)
        path.write_text(path.read_text().replace('effect_id = "unknown"', 'effect_id = "heal"'))
        path.write_text(path.read_text().replace('effect_parameters = {"heal": 18}', 'effect_parameters = {"heal": 0}'))
        self.assertIn('invalid effect parameter heal', self.run_cli('validate', success=False).stderr)
        path.write_text(path.read_text().replace('effect_parameters = {"heal": 0}', 'effect_parameters = {"heal": 18}'))
        path = self.root / 'content/encounters/clearing.tres'
        original = path.read_text()
        path.write_text(original.replace('"form_id": "moss"', '"form_id": "ember"'))
        self.assertIn('unknown enemy species or form', self.run_cli('validate', success=False).stderr)
        path.write_text(original.replace('"nature": "forest"', '"nature": "unknown"', 1))
        self.assertIn('unknown enemy action reference', self.run_cli('validate', success=False).stderr)


if __name__ == '__main__':
    unittest.main()
