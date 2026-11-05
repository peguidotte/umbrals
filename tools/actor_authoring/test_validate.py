"""Independent numeric fixtures and real-release compatibility checks."""
import contextlib
import copy
import io
import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tools.actor_authoring.validate import CHANNELS, main, validate_profile
from asset_pipeline import AssetError, ROOT, file_record, write_json
from tools.umbrals import ID as CONTENT_ID


def frames(offset):
    # Numeric test data, not a produced character animation.
    rest = [0.0] * len(CHANNELS)
    rest[3:5] = [1.0, 1.0]
    poses = [rest.copy() for _ in range(3)]
    poses[1][0] = offset
    return poses


class ActorAuthoringTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="umbral-actor-test-")
        self.root = Path(self.temporary.name)
        (self.root / "assets/schemas").mkdir(parents=True)
        shutil.copyfile(ROOT / "assets/schemas/module-v1.schema.json",
                        self.root / "assets/schemas/module-v1.schema.json")
        write_json(self.root / "assets/domains.json", {"domains": {"characters": "Actors", "attacks": "Effects"}})
        self.form = {"ground": [0.5, 0.95], "anatomy": {"mouth": [0.8, 0.4]},
                     "states": {"0": frames(0.1), "3": frames(0.2)},
                     "attacks": {"0": frames(0.3)}, "reactions": {"0": frames(0.4)}}
        self.motion = {"schema": 1, "fps": 30, "channels": CHANNELS.copy(), "forms": {"ember": self.form}}
        self.performances = {"schema": 1, "parts": ["mouth"], "specs": [
            {"index": 0, "start": 0, "release": 0.01, "contact": 0.02,
             "end": 0.06, "beats": [0.02], "hold": 0.01}]}
        self.profile = json.loads((Path(__file__).parent / "examples/brasa-v1.json").read_text())
        self.profile["attacks"] = [0]
        self.profile_path = self.root / "profile.json"
        self.save()

    def tearDown(self):
        self.temporary.cleanup()

    def module(self, reference, payload):
        folder = self.root / "assets" / reference["id"] / "versions" / reference["version"]
        path = folder / "data.json"
        write_json(path, payload)
        write_json(folder / "manifest.json", {"schema_version": 1, "id": reference["id"],
                   "version": reference["version"], "status": "draft", "description": "Numeric test fixture",
                   "provenance": {"kind": "test fixture"}, "dependencies": [],
                   "files": {reference["role"]: file_record(path, "data.json", "data")}})
        return path

    def save(self):
        self.motion_path = self.module(self.profile["motion_source"], self.motion)
        self.performance_path = self.module(self.profile["performances_source"], self.performances)
        write_json(self.profile_path, self.profile)

    def validate(self):
        return validate_profile(self.profile_path, self.root)

    def rejects(self, message):
        self.save()
        with self.assertRaisesRegex(AssetError, message):
            self.validate()

    def test_known_gap_is_valid_but_incomplete(self):
        report = self.validate()
        self.assertTrue(report["valid"])
        self.assertFalse(report["complete"])
        self.assertEqual([g["requirement"] for g in report["gaps"]], ["walk"])
        self.assertEqual(report["attacks"][0]["normalized_source_point"], [0.8, 0.4])

    def test_missing_requirement_cannot_disappear(self):
        del self.profile["states"]["walk"]
        self.rejects("Profile schema")

    def test_complete_requires_separate_real_track(self):
        self.form["states"]["6"] = frames(0.5)
        self.profile["states"]["walk"] = {"group": "states", "clip": "6"}
        self.save()
        self.assertTrue(self.validate()["complete"])

    def test_idle_cannot_be_relabelled_walk(self):
        self.profile["states"]["walk"] = copy.deepcopy(self.profile["states"]["idle"])
        self.rejects("identical samples")

    def test_static_placeholder_is_rejected(self):
        self.form["states"]["0"] = [frames(0)[0]] * 3
        self.rejects("static placeholder")

    def test_missing_track_is_rejected_without_fallback(self):
        del self.form["states"]["3"]
        self.rejects("hurt: missing")

    def test_content_form_id_with_underscore_is_accepted(self):
        form_id = "brasa_adulto"
        self.assertIsNotNone(CONTENT_ID.fullmatch(form_id))
        self.profile["form_id"] = form_id
        self.motion["forms"] = {form_id: self.form}
        self.save()
        report = self.validate()
        self.assertTrue(report["valid"])
        self.assertEqual(report["form_id"], form_id)

    def test_hyphenated_form_id_is_rejected_like_content(self):
        form_id = "brasa-adulto"
        self.assertIsNone(CONTENT_ID.fullmatch(form_id))
        self.profile["form_id"] = form_id
        self.motion["forms"] = {form_id: self.form}
        self.rejects("Profile schema")

    def test_missing_form_is_rejected_without_proxy(self):
        self.profile["form_id"] = "spore"
        self.rejects("Missing authored form")

    def test_missing_socket_is_rejected_without_mouth_fallback(self):
        self.performances["parts"][0] = "tail"
        self.rejects("missing explicit socket 'tail'")

    def test_socket_must_be_normalized(self):
        self.form["anatomy"]["mouth"] = [1.2, 0.4]
        self.rejects("normalized coordinates")

    def test_ground_must_be_normalized(self):
        self.form["ground"] = [0.4, -1]
        self.rejects("ground pivot")

    def test_reaction_required_for_each_attack(self):
        del self.form["reactions"]["0"]
        self.rejects("reaction: missing")

    def test_clip_width_is_runtime_width(self):
        self.form["attacks"]["0"][1].pop()
        self.rejects("invalid sample 1")

    def test_bool_is_not_a_channel_number(self):
        self.form["states"]["3"][0][0] = True
        self.rejects("invalid sample")

    def test_non_finite_number_is_rejected(self):
        self.form["states"]["3"][0][0] = float("nan")
        self.rejects("Non-finite")

    def test_scale_cannot_collapse(self):
        self.form["states"]["3"][0][3] = 0
        self.rejects("non-positive scale")

    def test_channel_order_cannot_drift(self):
        self.motion["channels"][0], self.motion["channels"][1] = self.motion["channels"][1], self.motion["channels"][0]
        self.rejects("runtime channel order")

    def test_fps_cannot_disagree_with_runtime(self):
        self.motion["fps"] = 60
        self.rejects("30 FPS")

    def test_contact_cannot_precede_release(self):
        self.performances["specs"][0]["release"] = 0.03
        self.rejects("event clock")

    def test_attack_cannot_end_after_its_track(self):
        self.performances["specs"][0]["end"] = 1
        self.rejects("event clock")

    def test_beats_cannot_extend_after_recovery(self):
        self.performances["specs"][0]["beats"] = [0.9]
        self.rejects("contact beats")

    def test_duplicate_attack_index_is_rejected(self):
        self.profile["attacks"] = [0, 0]
        self.rejects("Profile schema")

    def test_index_beyond_runtime_performances_is_rejected(self):
        self.profile["attacks"] = [15]
        self.rejects("Profile schema")

    def test_other_actor_format_requires_its_own_adapter(self):
        self.profile["format"] = "refuge-poses-v1"
        self.rejects("Profile schema")

    def test_corrupt_source_is_rejected(self):
        self.motion_path.write_text("{}")
        with self.assertRaisesRegex(AssetError, "Integrity mismatch"):
            self.validate()

    def test_unpinned_version_is_rejected(self):
        self.profile["motion_source"]["version"] = "latest"
        write_json(self.profile_path, self.profile)
        with self.assertRaisesRegex(AssetError, "Profile schema"):
            self.validate()

    def test_unsafe_release_file_path_is_rejected(self):
        path = self.motion_path.parent / "manifest.json"
        manifest = json.loads(path.read_text())
        manifest["files"]["motion"]["path"] = "../data.json"
        write_json(path, manifest)
        with self.assertRaisesRegex(AssetError, "Unsafe asset path"):
            self.validate()

    def test_cli_statuses_and_no_writes(self):
        before = {p.relative_to(self.root): p.read_bytes() for p in self.root.rglob("*") if p.is_file()}
        with contextlib.redirect_stdout(io.StringIO()) as stdout:
            self.assertEqual(main([str(self.profile_path), "--root", str(self.root)]), 0)
        self.assertFalse(json.loads(stdout.getvalue())["complete"])
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(main([str(self.profile_path), "--root", str(self.root), "--require-complete"]), 1)
            self.assertEqual(main([str(self.root / "absent.json"), "--root", str(self.root)]), 2)
        after = {p.relative_to(self.root): p.read_bytes() for p in self.root.rglob("*") if p.is_file()}
        self.assertEqual(before, after)


class PublishedCompatibilityTests(unittest.TestCase):
    def test_new_electric_profiles_have_states_and_attached_origins(self):
        for form_id in ['volt', 'tempestral']:
            with self.subTest(form=form_id):
                report = validate_profile(Path(__file__).parent / f'examples/{form_id}-v1.json')
                self.assertTrue(report['complete'])
                self.assertEqual(report['gaps'], [])
                self.assertEqual([a['socket'] for a in report['attacks']], ['quills', 'crest', 'fore', 'shoulder', 'quills', 'flank'])

    def test_brasa_profile_reads_real_releases(self):
        report = validate_profile(Path(__file__).parent / "examples/brasa-v1.json")
        self.assertTrue(report["valid"])
        self.assertFalse(report["complete"])
        self.assertEqual([a["socket"] for a in report["attacks"]], ["mouth", "tail", "fore"])
        self.assertEqual([a["cast_samples"] for a in report["attacks"]], [97] * 3)
        self.assertEqual([a["reaction_samples"] for a in report["attacks"]], [61] * 3)

    def test_eight_existing_forms_and_their_primary_sockets(self):
        profile = json.loads((Path(__file__).parent / "examples/brasa-v1.json").read_text())
        families = [("ember", 0), ("ignivar", 0), ("moss", 3), ("verdalio", 3),
                    ("dew", 6), ("mareveu", 6), ("volt", 9), ("tempestral", 9)]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "profile.json"
            for form_id, start in families:
                with self.subTest(form=form_id):
                    profile.update(form_id=form_id, attacks=list(range(start, start + 3)))
                    write_json(path, profile)
                    report = validate_profile(path)
                    self.assertTrue(report["valid"])
                    self.assertFalse(report["complete"])
                    self.assertEqual(len(report["attacks"]), 3)
                    self.assertEqual([g["requirement"] for g in report["gaps"]], ["walk"])


if __name__ == "__main__":
    unittest.main()
