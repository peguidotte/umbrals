"""Read-only pilot gates, including evidence from the native Godot renderer."""
from __future__ import annotations

import argparse
import json
import math
import subprocess
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from asset_pipeline import ROOT, digest, read_json, validate

RELEASE = "assets/characters/brasa-pilot/versions/0.1.0"


def report(root: Path = ROOT, native: Path | None = None) -> dict:
    modules = validate(root, base_ref="origin/main")
    manifest = read_json(root / RELEASE / "manifest.json")
    walk = read_json(root / RELEASE / "walk.json")
    for path, expected in manifest["provenance"]["source_files"].items():
        if digest(root / path) != expected:
            raise ValueError("Pinned authoring source changed: " + path)
    author = root / manifest["provenance"]["authoring_tool"]
    if digest(author) != manifest["provenance"]["authoring_sha256"]:
        raise ValueError("Authoring implementation no longer matches generated study")
    for path in ("assets/runtime-lock.json", "scripts/assets/binding_paths.gd"):
        base = subprocess.run(["git", "-C", str(root), "show", "origin/main:" + path],
                              capture_output=True, check=True)
        if (root / path).read_bytes() != base.stdout:
            raise ValueError("Pilot must not change production pins/bindings: " + path)
    frames = walk["forms"]["ember"]["states"]["6"]
    if walk["fps"] != 30 or len(frames) != 31 or len(walk["channels"]) != 20:
        raise ValueError("Unexpected walk clock or channel layout")
    if frames[0] != frames[-1] or not any(frame != frames[0] for frame in frames):
        raise ValueError("Walk must have motion and a closed endpoint")
    for frame in frames:
        if len(frame) != 20 or any(type(v) not in (int, float) or not math.isfinite(v) for v in frame):
            raise ValueError("Malformed channel sample")
        if frame[3] <= 0 or frame[4] <= 0:
            raise ValueError("Scale must stay positive")
    motion = read_json(root / "assets/characters/battle-motion/versions/1.0.0/motion.json")
    definition = motion["forms"]["ember"]
    effects = read_json(root / "assets/attacks/woodland-elements/versions/1.1.0/performances.json")
    sockets = []
    for index, part in enumerate(("mouth", "tail", "fore")):
        if effects["parts"][index] != part or part not in definition["anatomy"]:
            raise ValueError("Socket must be explicit; runtime fallback cannot satisfy this gate")
        clock = effects["specs"][index]
        if not 0 <= clock["start"] < clock["release"] < clock["contact"] < clock["end"] <= 3.2:
            raise ValueError("Invalid cast clock")
        sockets.append({"part": part, "rest_uv": definition["anatomy"][part],
                        "release_seconds": clock["release"], "contact_seconds": clock["contact"]})
    evidence = None
    if native:
        metrics = read_json(native / "native-projections.json")
        if not metrics.get("source_hashes"):
            raise ValueError("Native capture must attest its exact source inputs")
        for path, expected in metrics["source_hashes"].items():
            if digest(root / path) != expected:
                raise ValueError("Native capture source no longer matches: " + path)
        images = sorted(native.glob("frame-*.png"))
        if len(images) != 97 or metrics["frames"] != 97 or len(metrics["samples"]) != 97:
            raise ValueError("Native capture requires every frame and socket sample")
        for index, (image, sample) in enumerate(zip(images, metrics["samples"])):
            if sample["frame"] != index or abs(sample["seconds"] - index / 30) > 1e-5:
                raise ValueError("Native sample clock differs from the frame sequence")
            with Image.open(image) as picture:
                if picture.size != (1280, 720) or picture.convert("RGB").getextrema() == ((0, 0),) * 3:
                    raise ValueError("Native frame is blank or incorrectly sized")
            if len(sample["sockets"]) != 3:
                raise ValueError("Incomplete projected sockets")
            for part, point in zip(("mouth", "tail", "fore"), sample["sockets"]):
                if point["part"] != part or not (0 < point["x"] < 1280 and 0 < point["y"] < 720):
                    raise ValueError("Projected socket escaped the viewport")
        for index, socket in enumerate(sockets):
            release_frame = round(socket["release_seconds"] * 30)
            socket["native_release_sample"] = metrics["samples"][release_frame]["sockets"][index]
        evidence = {"engine": metrics["engine"]["string"], "frames": len(images),
                    "projected_socket_samples": 291,
                    "first_frame_sha256": digest(images[0]), "last_frame_sha256": digest(images[-1])}
    return {"slice": "V05-ART-01B", "valid": True, "production_ready": False,
            "modules": modules, "pilot": "characters/brasa-pilot@0.1.0",
            "walk": {"samples": len(frames), "fps": 30, "seconds": 1, "loop_closed": True,
                     "semantic_status": "blocking_candidate_not_approved_gait"},
            "existing_states": {"idle": "states/0", "hurt": "states/3"},
            "sockets": sockets, "native_evidence": evidence,
            "gaps": manifest["metadata"]["required_gaps"]}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--native-dir", type=Path)
    parser.add_argument("--require-production-ready", action="store_true")
    args = parser.parse_args()
    try:
        result = report(native=args.native_dir)
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as exc:
        print(json.dumps({"valid": False, "error": str(exc)}))
        raise SystemExit(2)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    raise SystemExit(1 if args.require_production_ready and not result["production_ready"] else 0)
