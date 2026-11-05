"""Validate declared actor requirements against exact, existing asset releases."""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import sys

from jsonschema import Draft202012Validator

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
from asset_pipeline import AssetError, ROOT, digest, inside, load_releases, read_json

CHANNELS = ["x", "y", "rotation", "sx", "sy", "bob", "inflate", "blink", "head",
            "tail", "fore", "hind", "crest", "ear", "jaw", "wing", "feeler", "bough",
            "fin", "reach"]
SCHEMA = Path(__file__).with_name("profile-v1.schema.json")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssetError(message)


def number(value: object) -> bool:
    try:
        return type(value) in (int, float) and math.isfinite(value)
    except OverflowError:
        return False


def point(value: object, label: str) -> None:
    require(isinstance(value, list) and len(value) == 2 and
            all(number(v) and 0 <= v <= 1 for v in value),
            f"{label}: expected two finite normalized coordinates in [0, 1]")


def source(root: Path, releases: dict, reference: dict) -> tuple[dict, dict]:
    key = (reference["id"], reference["version"])
    require(key in releases, f"Unknown exact release: {key}")
    manifest_path, manifest = releases[key]
    role = reference["role"]
    require(role in manifest["files"], f"Unknown file role {role!r} in {key}")
    record = manifest["files"][role]
    require(record["kind"] == "data", f"Expected data role: {key}:{role}")
    path = inside(manifest_path.parent, record["path"])
    require(path.is_file(), f"Missing source file: {path.relative_to(root)}")
    require(path.stat().st_size == record["bytes"] and digest(path) == record["sha256"],
            f"Integrity mismatch: {path.relative_to(root)}")
    value = read_json(path)
    require(isinstance(value, dict), f"Expected source object: {path.relative_to(root)}")
    return value, {**reference, "path": path.relative_to(root).as_posix(),
                   "sha256": record["sha256"], "status": manifest["status"]}


def track(form: dict, group: str, clip: str, label: str) -> list:
    tracks = form.get(group)
    require(isinstance(tracks, dict) and clip in tracks, f"{label}: missing {group}/{clip}")
    frames = tracks[clip]
    require(isinstance(frames, list) and len(frames) >= 2, f"{label}: needs at least two samples")
    for index, frame in enumerate(frames):
        require(isinstance(frame, list) and len(frame) == len(CHANNELS) and
                all(number(v) for v in frame), f"{label}: invalid sample {index}")
        require(frame[3] > 0 and frame[4] > 0, f"{label}: non-positive scale at sample {index}")
    require(any(frame != frames[0] for frame in frames[1:]), f"{label}: static placeholder track")
    return frames


def attack(form: dict, performances: dict, index: int, fps: int) -> dict:
    label = f"attack {index}"
    specs, parts = performances.get("specs"), form.get("parts", performances.get("parts"))
    require(isinstance(specs, list) and isinstance(parts, list) and
            index < len(specs) and index < len(parts), f"{label}: missing performance")
    spec, socket = specs[index], parts[index]
    require(isinstance(spec, dict) and type(spec.get("index")) is int and spec["index"] == index,
            f"{label}: mismatched performance index")
    require(isinstance(socket, str) and socket, f"{label}: invalid socket name")
    anatomy = form.get("anatomy", {})
    require(isinstance(anatomy, dict) and socket in anatomy,
            f"{label}: missing explicit socket {socket!r}; runtime fallback is not authoring evidence")
    point(anatomy[socket], f"{label} socket {socket}")
    frames = track(form, "attacks", str(index), label)
    reaction = track(form, "reactions", str(index), f"{label} reaction")
    keys = ("start", "release", "contact", "end")
    require(all(number(spec.get(key)) for key in keys), f"{label}: invalid event clock")
    times = [spec[key] for key in keys]
    duration = (len(frames) - 1) / fps
    require(0 <= times[0] <= times[1] <= times[2] <= times[3] <= duration,
            f"{label}: event clock outside track or out of order")
    beats = spec.get("beats")
    require(isinstance(beats, list) and beats and all(number(t) and
            spec["contact"] <= t <= spec["end"] for t in beats) and beats == sorted(beats),
            f"{label}: invalid contact beats")
    require(number(spec.get("hold")) and 0 <= spec["hold"] <= (len(reaction) - 1) / fps,
            f"{label}: invalid contact hold")
    return {"index": index, "socket": socket, "normalized_source_point": anatomy[socket],
            "release_seconds": spec["release"], "contact_seconds": spec["contact"],
            "cast_samples": len(frames), "reaction_samples": len(reaction)}


def validate_profile(path: Path, root: Path = ROOT) -> dict:
    profile = read_json(path)
    errors = sorted(Draft202012Validator(read_json(SCHEMA)).iter_errors(profile), key=str)
    require(not errors, f"Profile schema: {errors[0].message}" if errors else "")
    releases = load_releases(root)
    motion, motion_evidence = source(root, releases, profile["motion_source"])
    performances, performance_evidence = source(root, releases, profile["performances_source"])
    require(type(motion.get("schema")) is int and motion["schema"] == 1 and
            motion.get("channels") == CHANNELS and type(motion.get("fps")) is int and motion["fps"] == 30,
            "Unsupported battle-motion layout; expected schema 1, 30 FPS and runtime channel order")
    require(type(performances.get("schema")) is int and performances["schema"] == 1,
            "Unsupported performances schema")
    forms, form_id = motion.get("forms"), profile["form_id"]
    require(isinstance(forms, dict) and isinstance(forms.get(form_id), dict),
            f"Missing authored form {form_id!r}; proxy rigs are not accepted")
    form = forms[form_id]
    point(form.get("ground"), "ground pivot")
    states, gaps, used = {}, [], []
    for name, binding in profile["states"].items():
        if "missing" in binding:
            gaps.append({"requirement": name, "reason": binding["missing"]})
            states[name] = {"status": "missing"}
            continue
        frames = track(form, binding["group"], binding["clip"], name)
        require(all(frames != prior for prior in used), f"{name}: another required state uses identical samples")
        used.append(frames)
        states[name] = {"status": "present", **binding, "samples": len(frames)}
    attacks = [attack(form, performances, index, motion["fps"]) for index in profile["attacks"]]
    return {"schema_version": 1, "valid": True, "complete": not gaps,
            "form_id": form_id, "format": profile["format"], "sources": [motion_evidence, performance_evidence],
            "states": states, "attacks": attacks, "gaps": gaps,
            "limits": ["Numeric/source checks only; posed socket alignment and walk semantics require visual review.",
                       "No runtime binding, art approval or production readiness is established."]}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("profile", type=Path)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--require-complete", action="store_true", help="Fail if any required state is declared missing")
    args = parser.parse_args(argv)
    try:
        report = validate_profile(args.profile, args.root)
    except (AssetError, OSError, ValueError) as error:
        print(json.dumps({"valid": False, "complete": False, "error": str(error)}))
        return 2
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 1 if args.require_complete and not report["complete"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
