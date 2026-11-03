import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('umbrals', ROOT / 'tools/umbrals.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class CatalogValidationTest(unittest.TestCase):
    def test_branch_and_invalid_content(self):
        source = (ROOT / 'content/species/ember/species.tres').read_text()
        bindings = json.loads((ROOT / 'assets/runtime-lock.json').read_text())['bindings']
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory) / 'ember'
            folder.mkdir()
            path = folder / 'species.tres'
            _, _, forms, _ = module.read_package(ROOT / 'content/species/ember/species.tres')
            third = dict(forms[1], id='third')
            source = source.replace('\n])\nevolutions', '\n' + json.dumps(third) + '\n])\nevolutions', 1)
            source = source.replace('}])', '}, {"id": "branch", "from": "ember", "to": "third"}])')
            path.write_text(source)
            self.assertEqual(module.validate(path, bindings), [])
            path.write_text(source.replace('"to": "third"', '"to": "missing"'))
            self.assertTrue(module.validate(path, bindings))
            path.write_text(source.replace('umbrals/ember', 'umbrals/missing'))
            self.assertTrue(module.validate(path, bindings))
            path.write_text(source.replace('"id": "third"', '"id": "Bad-ID"'))
            self.assertTrue(module.validate(path, bindings))
            path.write_text(source.replace('combustion', 'unknown_trait'))
            self.assertTrue(module.validate(path, bindings))
            cycle = source.replace('}])', '}, {"id": "loop", "from": "third", "to": "ember"}])')
            path.write_text(cycle)
            self.assertTrue(any('cycle' in error for error in module.validate(path, bindings)))
            unreachable = source.replace(', {"id": "branch", "from": "ember", "to": "third"}', '')
            path.write_text(unreachable)
            self.assertTrue(any('unreachable' in error for error in module.validate(path, bindings)))
            other = Path(directory) / 'other'
            other.mkdir()
            other_path = other / 'species.tres'
            other_path.write_text(source.replace('id = "ember"', 'id = "other"', 1))
            path.write_text(source)
            self.assertTrue(module.duplicate_form_ids([path, other_path]))
            for reserved in ('owl', 'stag'):
                path.write_text(source.replace('"id": "third"', f'"id": "{reserved}"').replace('"to": "third"', f'"to": "{reserved}"'))
                self.assertTrue(any('reserved for encounter' in error for error in module.validate(path, bindings)))
            invalid_replacements = [
                ('"max_hp": 40', '"max_hp": 0'),
                ('"attack": 10', '"attack": -1'),
                ('"speed": 14', '"speed": true'),
                ('"trait_value": 2', '"trait_value": -1'),
                ('"damage": 0, "block": 0', '"damage": -1, "block": 0'),
                ('"resistances": {"fire": 25}', '"resistances": {"fire": 101}'),
                ('"resistances": {"fire": 25}', '"resistances": {"bogus": 10}'),
                ('"name": "Brasa"', '"name": ""'),
                ('"title": "Quem guarda a última brasa"', '"title": ""'),
                ('"nature": "fire"', '"nature": "bogus"'),
                ('"fireball", "cinder_claw"', '"missing_power", "cinder_claw"'),
                ('"fierce", "resilient"', '"missing_passive", "resilient"'),
                ('signature = "inferno"', 'signature = "fireball"'),
                ('color = "ef987b"', 'color = "wrong"'),
            ]
            for original, replacement in invalid_replacements:
                with self.subTest(replacement=replacement):
                    self.assertIn(original, source)
                    path.write_text(source.replace(original, replacement, 1))
                    self.assertTrue(module.validate(path, bindings))

if __name__ == '__main__':
    unittest.main()
