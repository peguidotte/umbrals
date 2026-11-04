"""Behavioral safeguards for unpublished authoring and anatomy ownership."""
import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from tools.brasa_pilot.build import ATLAS, MOTION, RELEASE, ROOT, build


class BuildSafeguards(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for relative in (ATLAS, MOTION):
            destination = self.root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / relative, destination)
        self.git("init", "-q")
        self.git("add", "assets")
        self.git("-c", "user.name=Pilot Test", "-c", "user.email=pilot@example.invalid",
                 "commit", "-qm", "Published source fixture")
        self.git("update-ref", "refs/remotes/origin/main", "HEAD")

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.root), *args], check=True, capture_output=True)

    def payload(self):
        return {path.name: path.read_bytes() for path in (self.root / RELEASE).glob("*.json")}

    def test_reauthoring_is_deterministic_and_preserves_sources(self):
        before = {relative: (self.root / relative).read_bytes() for relative in (ATLAS, MOTION)}
        build(self.root)
        authored = self.payload()
        build(self.root)
        self.assertEqual(authored, self.payload())
        self.assertEqual(before, {relative: (self.root / relative).read_bytes() for relative in before})
        self.assertFalse((self.root / "assets/runtime-lock.json").exists())

    def test_published_release_cannot_be_rewritten(self):
        build(self.root)
        before = self.payload()
        self.git("add", "assets")
        self.git("-c", "user.name=Pilot Test", "-c", "user.email=pilot@example.invalid",
                 "commit", "-qm", "Published pilot fixture")
        self.git("update-ref", "refs/remotes/origin/main", "HEAD")
        with self.assertRaisesRegex(ValueError, "immutable"):
            build(self.root)
        self.assertEqual(before, self.payload())

    def test_missing_tail_is_rejected_without_mouth_fallback(self):
        source = self.root / MOTION
        data = json.loads(source.read_text())
        del data["forms"]["ember"]["anatomy"]["tail"]
        source.write_text(json.dumps(data))
        with self.assertRaisesRegex(ValueError, "explicit socket: tail"):
            build(self.root)
        self.assertFalse((self.root / RELEASE).exists())


if __name__ == "__main__":
    unittest.main()
