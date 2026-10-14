"""Behavioral contract for safe, pinned and independently versioned asset releases."""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

from PIL import Image

TOOLS = Path(__file__).resolve().parents[1] / "tools"
sys.path.insert(0, str(TOOLS))
from asset_pipeline import AssetError, ROOT, build, file_record, read_json, validate, write_json
from normalize_atlas import repack_pages


class AssetPipelineTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="umbral-asset-test-")
        self.root = Path(self.temporary.name)
        (self.root / "assets/schemas").mkdir(parents=True)
        shutil.copyfile(ROOT / "assets/schemas/module-v1.schema.json", self.root / "assets/schemas/module-v1.schema.json")
        write_json(self.root / "assets/domains.json", {"domains": {"attacks": "Attacks", "characters": "Characters", "items": "Items"}})
        self.path, self.data = self.module("attacks/test")
        write_json(self.root / "assets/runtime-lock.json", {"schema_version": 1, "bindings": {
            "attacks/test": {"id": "attacks/test", "version": "1.0.0", "file": "sheet"}}})
        build(self.root)

    def tearDown(self):
        self.temporary.cleanup()

    def module(self, asset_id, version="1.0.0"):
        folder = self.root / "assets" / asset_id / "versions" / version
        folder.mkdir(parents=True)
        image = Image.new("RGBA", (4, 4));image.putpixel((0, 0), (255, 0, 50, 255));image.save(folder / "sheet.png")
        data = {"schema_version": 1, "id": asset_id, "version": version, "status": "production", "description": "Test asset",
                "provenance": {"kind": "test fixture"}, "dependencies": [],
                "files": {"sheet": file_record(folder / "sheet.png", "sheet.png", "texture")},
                "animations": {"cast": {"file": "sheet", "frame_size": [2, 2], "frames": 3,
                                        "columns": 2, "fps": 30, "pivot": [1, 1], "loop": False}}}
        path = folder / "manifest.json";write_json(path, data)
        return path, data

    def save(self):
        write_json(self.path, self.data)

    def cli(self, *args, success=True):
        result = subprocess.run([sys.executable, str(TOOLS / "assets.py"), "--root", str(self.root), *args], capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.root), *args], check=True, capture_output=True, text=True).stdout.strip()

    def commit_base(self):
        self.git("init", "--initial-branch=main")
        self.git("config", "user.name", "Asset tests");self.git("config", "user.email", "assets@example.invalid")
        self.git("add", ".");self.git("commit", "-m", "Publish asset 1.0.0")
        return self.git("rev-parse", "HEAD")

    def test_valid_release_and_exact_pins(self):
        self.assertEqual(validate(self.root)["releases"], 1)

    def test_rejects_corrupt_payload(self):
        (self.path.parent / "sheet.png").write_bytes(b"corrupt")
        with self.assertRaisesRegex(AssetError, "Integrity mismatch"):validate(self.root)

    def test_rejects_file_outside_release(self):
        self.data["files"]["sheet"]["path"] = "../../outside.png";self.save()
        with self.assertRaisesRegex(AssetError, "Unsafe asset path"):validate(self.root)

    def test_rejects_symlink_even_when_it_points_inside(self):
        (self.path.parent / "linked.png").symlink_to("sheet.png")
        self.data["files"]["sheet"]["path"] = "linked.png";self.save()
        with self.assertRaisesRegex(AssetError, "symlink"):validate(self.root)

    def test_rejects_extra_unowned_payload(self):
        (self.path.parent / "forgotten.txt").write_text("untracked")
        with self.assertRaisesRegex(AssetError, "Untracked files"):validate(self.root)

    def test_rejects_stale_generated_index(self):
        self.data["description"] = "Changed";self.save()
        with self.assertRaisesRegex(AssetError, "Stale generated"):validate(self.root)

    def test_rejects_bad_grid(self):
        self.data["animations"]["cast"]["frames"] = 5;self.save()
        with self.assertRaisesRegex(AssetError, "grid"):validate(self.root)

    def test_rejects_bad_pivot(self):
        self.data["animations"]["cast"]["pivot"] = [2, 1];self.save()
        with self.assertRaisesRegex(AssetError, "pivot"):validate(self.root)

    def test_rejects_unknown_dependency(self):
        self.data["dependencies"] = [{"id": "characters/missing", "version": "1.0.0"}];self.save()
        with self.assertRaisesRegex(AssetError, "Unresolved dependency"):validate(self.root)

    def test_production_cannot_depend_on_prototype(self):
        path, other = self.module("characters/rig")
        other["status"] = "prototype";write_json(path, other)
        self.data["dependencies"] = [{"id": "characters/rig", "version": "1.0.0"}];self.save()
        with self.assertRaisesRegex(AssetError, "non-production art"):validate(self.root)

    def test_rejects_missing_performance_effect(self):
        self.data["performances"] = {"hand": {"charge": "missing"}};self.save()
        with self.assertRaisesRegex(AssetError, "unknown local animation"):validate(self.root)

    def test_rejects_dependency_cycle(self):
        path, other = self.module("characters/rig")
        other["dependencies"] = [{"id": "attacks/test", "version": "1.0.0"}];write_json(path, other)
        self.data["dependencies"] = [{"id": "characters/rig", "version": "1.0.0"}];self.save()
        with self.assertRaisesRegex(AssetError, "Cyclic"):validate(self.root)

    def test_rejects_implicit_latest_version(self):
        lock = read_json(self.root / "assets/runtime-lock.json")
        lock["bindings"]["attacks/test"]["version"] = "latest";write_json(self.root / "assets/runtime-lock.json", lock)
        with self.assertRaisesRegex(AssetError, "Unknown pinned release"):validate(self.root)

    def test_does_not_silently_advance_game_pin(self):
        self.module("attacks/test", "1.1.0");build(self.root)
        lock = read_json(self.root / "assets/runtime-lock.json")
        self.assertEqual(lock["bindings"]["attacks/test"]["version"], "1.0.0")
        self.assertEqual(validate(self.root)["releases"], 2)

    def test_prototype_cannot_be_bound_into_production(self):
        self.data["status"] = "prototype";self.save()
        with self.assertRaisesRegex(AssetError, "prototype art"):validate(self.root)

    def test_rejects_duplicate_json_keys(self):
        self.path.write_text('{"id":"a","id":"b"}')
        with self.assertRaisesRegex(AssetError, "Duplicate JSON key"):validate(self.root)

    def test_rejects_non_finite_metadata(self):
        self.path.write_text(self.path.read_text().replace('"fps": 30', '"fps": NaN'))
        with self.assertRaisesRegex(AssetError, "Non-finite"):validate(self.root)

    def test_published_release_and_schema_are_immutable(self):
        base = self.commit_base()
        self.data["description"] = "Replaced old art";self.save();build(self.root)
        with self.assertRaisesRegex(AssetError, "immutable"):validate(self.root, base_ref=base)
        self.git("checkout", "--", "assets", "scripts")
        schema = self.root / "assets/schemas/module-v1.schema.json";schema.write_text(schema.read_text() + "\n")
        with self.assertRaisesRegex(AssetError, "immutable"):validate(self.root, base_ref=base)

    def test_bump_preserves_old_release_and_does_not_promote_draft(self):
        base = self.commit_base();original = self.path.read_bytes()
        self.cli("bump", "attacks/test", "--from", "1.0.0", "--to", "1.0.1", "--change", "Refine silhouette")
        self.assertEqual(self.path.read_bytes(), original)
        new = read_json(self.path.parent.parent / "1.0.1/manifest.json")
        self.assertEqual(new["status"], "draft")
        self.assertEqual(validate(self.root, base_ref=base)["releases"], 2)
        self.cli("bump", "attacks/test", "--from", "1.0.0", "--to", "1.0.1", "--change", "Overwrite", success=False)

    def test_refresh_refuses_published_release(self):
        self.commit_base()
        self.cli("refresh", "attacks/test", "1.0.0", "--base-ref", "HEAD", success=False)

    def test_new_domain_module_is_empty_draft_not_fake_art(self):
        self.cli("new", "items/amulet", "--description", "Future item")
        data = read_json(self.root / "assets/items/amulet/versions/1.0.0/manifest.json")
        self.assertEqual(data["files"], {});self.assertEqual(data["status"], "draft")
        self.assertEqual(validate(self.root)["releases"], 2)

    def test_paged_repack_keeps_every_source_pixel_and_order(self):
        source = self.root / "sheet-source.png"
        image = Image.new("RGBA", (8, 4))
        for n in range(8):
            image.paste((n*30, 70, 180, 255), (n%4*2, n//4*2, n%4*2+2, n//4*2+2))
        image.save(source)
        columns, pages = repack_pages(source, self.root / "packed.png", 2, 2, 8, 4, limit=4)
        self.assertEqual(columns, 2);self.assertEqual([count for _,count in pages], [4,4])
        n = 0
        for path,count in pages:
            with Image.open(path) as packed:
                self.assertLessEqual(max(packed.size),4)
                for index in range(count):
                    actual = packed.crop((index%2*2,index//2*2,index%2*2+2,index//2*2+2))
                    original = image.crop((n%4*2,n//4*2,n%4*2+2,n//4*2+2))
                    self.assertEqual(actual.tobytes(),original.tobytes());n+=1


if __name__ == "__main__":unittest.main()
