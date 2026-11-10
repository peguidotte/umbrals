"""Coverage, exact references and promotion failures over isolated asset releases."""
import copy
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from asset_pipeline import AssetError, ROOT, build, file_record, read_json, validate, write_json
from card_asset_pipeline import BINDING, export_gate, snapshot, validate_presentation


class CardAssetTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='umbral-card-test-')
        self.root = Path(self.temp.name)
        schema = self.root / 'assets/schemas'
        schema.mkdir(parents=True)
        for name in ['module-v1.schema.json', 'card-presentation-v1.schema.json']:
            shutil.copy2(ROOT / 'assets/schemas' / name, schema / name)
        write_json(self.root / 'assets/domains.json', {'domains': {'ui': 'UI'}})
        write_json(self.root / 'assets/runtime-lock.json', {'schema_version': 1, 'bindings': {}})
        self.visual_path = self.root / 'assets/ui/test-visual/versions/1.0.0'
        self.visual_path.mkdir(parents=True)
        image = Image.new('RGBA', (8, 8));image.putpixel((3, 3), (255, 200, 80, 255));image.save(self.visual_path / 'visual.png')
        self.roles = ['frame', 'art-a', 'art-b', 'border', 'title', 'owner', 'portrait']
        files = {}
        for role in self.roles:
            shutil.copy2(self.visual_path / 'visual.png', self.visual_path / (role + '.png'))
            files[role] = file_record(self.visual_path / (role + '.png'), role + '.png', 'texture')
        (self.visual_path / 'visual.png').unlink()
        self.visual_module = {'schema_version': 1, 'id': 'ui/test-visual', 'version': '1.0.0', 'status': 'production', 'description': 'Synthetic test pixels; never production artwork', 'provenance': {'kind': 'test fixture'}, 'files': files, 'dependencies': []}
        write_json(self.visual_path / 'manifest.json', self.visual_module)
        self.path = self.root / 'assets/ui/power-card-system/versions/1.0.0'
        self.path.mkdir(parents=True)
        self.demand = {'entries': [{'species_id': 'moss', 'form_id': 'moss', 'power_id': 'shared', 'nature': 'forest', 'reasons': ['learnable']}, {'species_id': 'moss', 'form_id': 'adult', 'power_id': 'shared', 'nature': 'water', 'reasons': ['retained_from:moss']}], 'forms': {'moss': {'species_id': 'moss'}, 'adult': {'species_id': 'moss'}}, 'natures': ['forest', 'water'], 'enemy_portraits': {'characters/spore': {}}, 'compatibility_fixtures': []}
        def portrait():
            return {**self.entry('portrait'), 'crop': [0, 0, 1, 1], 'focal_point': [.5, .5]}
        self.data = {'schema_version': 1, 'layout_version': 1, 'visual_references': [{'library_file_id': 'libfile_test', 'purpose': 'synthetic fixture', 'availability': 'inspected'}], 'families': {'moss': {'default_frame': self.entry('frame'), 'reuse_default_for_forms': ['moss', 'adult'], 'form_overrides': {}}}, 'power_styles': {nature: {'art_border': self.entry('border'), 'title_plate': self.entry('title'), 'owner_plate': self.entry('owner'), 'tokens': {'background': '#101c23', 'foreground': '#f3e6c5'}} for nature in ['forest', 'water']}, 'illustrations': {'moss': {'moss': {'shared': self.entry('art-a')}, 'adult': {'shared': self.entry('art-b')}}}, 'target_portraits': {form: portrait() for form in ['moss', 'adult']}, 'enemy_portraits': {'characters/spore': portrait()}, 'layout': {'aspect': .65, 'art_region': [.1, .1, .8, .6], 'safe_region': [.05, .05, .9, .9], 'anchors': {'title': [.5, .2], 'owner': [.5, .9], 'cost': [.1, .1], 'target': [.9, .1]}, 'text': {'native': True, 'title_max_lines': 2, 'owner_max_lines': 1}, 'review': 'Synthetic fixture review'}, 'coverage': {'scope': 'catalog', 'demonstrations': [], 'pending': []}}
        self.module = {'schema_version': 1, 'id': BINDING, 'version': '1.0.0', 'status': 'production', 'description': 'Synthetic fixture', 'provenance': {'kind': 'test fixture'}, 'files': {}, 'dependencies': [{'id': 'ui/test-visual', 'version': '1.0.0'}]}
        self.save()

    def tearDown(self):
        self.temp.cleanup()

    def entry(self, role):
        return {'asset': {'id': 'ui/test-visual', 'version': '1.0.0', 'role': role}, 'status': 'approved', 'review': 'Synthetic fixture identity reviewed'}

    def save(self):
        write_json(self.path / 'presentation.json', self.data)
        self.module['files']['presentation'] = file_record(self.path / 'presentation.json', 'presentation.json', 'data')
        write_json(self.path / 'manifest.json', self.module)
        build(self.root)

    def check_data(self, mode='production'):
        self.save()
        return validate_presentation(self.root, (BINDING, '1.0.0'), self.demand, mode)

    def test_complete_reviewed_fixture_passes(self):
        report = self.check_data()
        self.assertTrue(report['ready'])
        self.assertEqual((report['required'], report['covered'], report['approved']), (2, 2, 2))
        self.assertEqual(validate(self.root)['releases'], 2)

    def test_authored_layout_cannot_escape_normalized_card_bounds(self):
        for name in ['art_region', 'safe_region']:
            with self.subTest(region=name):
                original = self.data['layout'][name]
                self.data['layout'][name] = [.9, .1, .4, .8]
                with self.assertRaisesRegex(AssetError, 'layout region escapes'):
                    self.check_data()
                self.data['layout'][name] = original

    def test_missing_art_is_reported_and_never_inherited(self):
        self.data['illustrations']['moss']['adult']['shared']['asset'] = None
        self.data['coverage']['pending'] = ['illustration:moss/adult/shared']
        report = self.check_data('development')
        self.assertEqual((report['failed'], report['covered']), (0, 1))
        self.assertFalse(report['ready'])
        self.assertGreater(self.check_data('production')['failed'], 0)

    def test_promotion_rejects_prototype_placeholder_and_blocked_reference(self):
        self.module['status'] = 'prototype'
        self.data['visual_references'][0]['availability'] = 'blocked'
        self.data['coverage']['scope'] = 'development'
        report = self.check_data()
        self.assertGreaterEqual(report['failed'], 3)

    def test_invalid_pin_or_role_never_resolves_latest(self):
        for field, value in [('version', '2.0.0'), ('id', 'ui/missing'), ('role', 'missing')]:
            with self.subTest(field=field):
                original = self.data['illustrations']['moss']['moss']['shared']['asset'][field]
                self.data['illustrations']['moss']['moss']['shared']['asset'][field] = value
                with self.assertRaises(AssetError): self.check_data()
                self.data['illustrations']['moss']['moss']['shared']['asset'][field] = original

    def test_no_implicit_default_for_new_form(self):
        self.data['families']['moss']['reuse_default_for_forms'].remove('adult')
        with self.assertRaisesRegex(AssetError, 'explicitly select'): self.check_data()

    def test_unused_default_frame_still_requires_exact_dependency(self):
        family = self.data['families']['moss']
        family['form_overrides'] = {'moss': self.entry('frame'), 'adult': self.entry('frame')}
        family['reuse_default_for_forms'] = []
        family['default_frame']['asset']['version'] = '99.0.0'
        with self.assertRaisesRegex(AssetError, 'exact declared dependency'): self.check_data()

    def test_unused_default_frame_cannot_hide_unapproved_art_in_production(self):
        family = self.data['families']['moss']
        family['form_overrides'] = {'moss': self.entry('frame'), 'adult': self.entry('frame')}
        family['reuse_default_for_forms'] = []
        family['default_frame']['status'] = 'prototype'
        with self.assertRaisesRegex(AssetError, 'unapproved'): self.check_data()

    def test_unknown_nature_form_and_nonplayable_combination_rejected(self):
        original = copy.deepcopy(self.data)
        self.data['power_styles']['ice'] = copy.deepcopy(self.data['power_styles']['water'])
        with self.assertRaisesRegex(AssetError, 'nature'): self.check_data()
        self.data = copy.deepcopy(original)
        self.data['illustrations']['moss']['ghost'] = self.data['illustrations']['moss'].pop('adult')
        with self.assertRaisesRegex(AssetError, 'unknown species/form'): self.check_data()
        self.data = original
        self.data['illustrations']['moss']['moss']['illegal'] = self.entry('art-a')
        with self.assertRaisesRegex(AssetError, 'nonplayable'): self.check_data()

    def test_explicit_demo_does_not_expand_production_demand(self):
        self.data['illustrations']['moss']['moss']['illegal'] = self.entry('art-a')
        for entry in self.data['illustrations']['moss']['moss'].values(): entry['reuse'] = {'reason': 'Synthetic fixture only', 'review': 'Same identity verified'}
        self.data['coverage']['demonstrations'] = [{'species_id': 'moss', 'form_id': 'moss', 'power_id': 'illegal', 'reason': 'isolated nonplayable composition test'}]
        self.assertEqual(self.check_data()['required'], 2)

    def test_reuse_needs_identity_review(self):
        self.data['illustrations']['moss']['adult']['shared'] = self.entry('art-a')
        with self.assertRaisesRegex(AssetError, 'reuse review'): self.check_data()

    def test_crop_and_focal_point_bounds(self):
        for crop, focal in [([.8, 0, .5, 1], [.9, .5]), ([0, 0, .5, 1], [.8, .5]), ([-.1, 0, 1, 1], [.5, .5])]:
            with self.subTest(crop=crop, focal=focal):
                self.data['target_portraits']['moss'].update(crop=crop, focal_point=focal)
                with self.assertRaises(AssetError): self.check_data()

    def test_transparency_and_contrast_verified(self):
        image = Image.new('RGBA', (8, 8), (1, 1, 1, 255));image.save(self.visual_path / 'frame.png')
        self.visual_module['files']['frame'] = file_record(self.visual_path / 'frame.png', 'frame.png', 'texture')
        write_json(self.visual_path / 'manifest.json', self.visual_module)
        with self.assertRaisesRegex(AssetError, 'transparent'): self.check_data()
        self.data['families']['moss']['default_frame'] = self.entry('border')
        self.data['power_styles']['forest']['tokens'] = {'background': '#ffffff', 'foreground': '#eeeeee'}
        with self.assertRaisesRegex(AssetError, 'contrast'): self.check_data()

    def test_stale_pending_inventory_fails(self):
        self.data['coverage']['pending'] = ['illustration:stale']
        with self.assertRaisesRegex(AssetError, 'inventory is stale'): self.check_data()

    def test_schema_rejects_traversal_floating_versions_and_unknown_fields(self):
        original = copy.deepcopy(self.data)
        for key, value in [('id', '../outside'), ('version', 'latest'), ('role', '../texture')]:
            self.data = copy.deepcopy(original)
            self.data['illustrations']['moss']['moss']['shared']['asset'][key] = value
            with self.assertRaisesRegex(AssetError, 'Invalid card presentation'): self.check_data()
        self.data = original
        self.data['damage'] = 99
        with self.assertRaisesRegex(AssetError, 'Invalid card presentation'): self.check_data()

    def test_duplicate_json_keys_rejected(self):
        (self.path / 'presentation.json').write_text('{"schema_version":1,"schema_version":1}')
        self.module['files']['presentation'] = file_record(self.path / 'presentation.json', 'presentation.json', 'data')
        write_json(self.path / 'manifest.json', self.module)
        with self.assertRaisesRegex(AssetError, 'Duplicate JSON key'): validate_presentation(self.root, (BINDING, '1.0.0'), self.demand)

    def test_integrity_and_data_binding_contract(self):
        self.module['files']['presentation']['sha256'] = '0' * 64
        write_json(self.path / 'manifest.json', self.module)
        with self.assertRaisesRegex(AssetError, 'integrity'): validate_presentation(self.root, (BINDING, '1.0.0'), self.demand)
        self.save()
        write_json(self.root / 'assets/runtime-lock.json', {'schema_version': 1, 'bindings': {BINDING: {'id': BINDING, 'version': '1.0.0', 'file': 'presentation'}}})
        with self.assertRaisesRegex(AssetError, 'loadable'): build(self.root)

    def test_legacy_export_stays_explicitly_disabled(self):
        self.assertFalse(export_gate(self.root)['enabled'])

    def test_pinned_export_gate_blocks_missing_art(self):
        shutil.copy2(self.visual_path / 'border.png', self.path / 'selection.png')
        self.module['files']['selection'] = file_record(self.path / 'selection.png', 'selection.png', 'texture')
        self.data['illustrations']['moss']['adult']['shared']['asset'] = None
        self.data['coverage']['pending'] = ['illustration:moss/adult/shared']
        self.save()
        write_json(self.root / 'assets/runtime-lock.json', {'schema_version': 1, 'bindings': {BINDING: {'id': BINDING, 'version': '1.0.0', 'file': 'selection'}}})
        build(self.root)
        with patch('card_asset_pipeline.snapshot', return_value=self.demand):
            with self.assertRaisesRegex(AssetError, 'production gate failed'): export_gate(self.root)

    def test_real_matrix_is_deterministic_and_retains_ancestral_water(self):
        first, second = snapshot(), snapshot()
        self.assertEqual(first, second)
        self.assertEqual((len(first['entries']), sum('initial' in row['reasons'] for row in first['entries']), sum('learnable' in row['reasons'] for row in first['entries'])), (73, 42, 70))
        retained = [row for row in first['entries'] if row['form_id'] == 'zuldar' and row['nature'] == 'water']
        self.assertEqual(len(retained), 3)
        self.assertTrue(all('retained_from:tempestral' in row['reasons'] and 'learnable' not in row['reasons'] for row in retained))
        self.assertFalse(any(row['form_id'] == 'dew' and row['power_id'] == 'thorn_lash' for row in first['entries']))
        self.assertGreaterEqual(len(first['compatibility_fixtures']), 43)

    def test_real_draft_fails_production_cli(self):
        result = subprocess.run([sys.executable, str(ROOT / 'tools/card_assets.py'), 'validate', '--mode', 'production', '--output', 'card-assets-negative.json'], cwd=ROOT, capture_output=True, text=True, timeout=90)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn('"covered": 0', result.stdout)


if __name__ == '__main__':
    unittest.main()
