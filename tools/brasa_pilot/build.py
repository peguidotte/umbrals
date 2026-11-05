"""Author one isolated locomotion blocking study; never promote runtime bindings."""
from __future__ import annotations

import math
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from asset_pipeline import ROOT, digest, file_record, read_json, write_json

RELEASE = "assets/characters/brasa-pilot/versions/0.1.0"
MOTION = "assets/characters/battle-motion/versions/1.0.0/motion.json"
ATLAS = "assets/characters/battle-creatures/versions/1.0.0/atlas.json"


def author_walk(channels: list[str]) -> list[list[float]]:
    """Closed 1 s loop in native channel order. This is blocking, not foot IK."""
    frames = []
    for frame in range(30):
        phase = math.tau * frame / 30
        values = dict.fromkeys(channels, 0.0)
        values.update(sx=1.0, sy=1.0, rotation=0.012 * math.sin(phase),
                      bob=-1.5 * (1 - math.cos(phase * 2)),
                      head=0.035 * math.sin(phase), tail=-0.065 * math.sin(phase),
                      fore=0.10 * math.sin(phase), hind=-0.18 * math.sin(phase),
                      ear=0.025 * math.sin(phase))
        frames.append([round(values[key], 6) for key in channels])
    return frames + [frames[0].copy()]


def build(root: Path = ROOT) -> None:
    folder = root / RELEASE
    subprocess.run(["git", "-C", str(root), "rev-parse", "--verify", "origin/main^{commit}"],
                   capture_output=True, check=True)
    published = subprocess.run(["git", "-C", str(root), "cat-file", "-e",
                                "origin/main:" + RELEASE + "/manifest.json"],
                               capture_output=True)
    if published.returncode == 0:
        raise ValueError("Published pilot is immutable; author a new version")
    source = read_json(root / MOTION)
    atlas = read_json(root / ATLAS)
    definition = source["forms"]["ember"]
    for part in ("mouth", "tail", "fore"):
        if part not in definition["anatomy"]:
            raise ValueError("Brasa requires an explicit socket: " + part)
    provenance = {
        "kind": "Original deterministic channel animation study over existing Brasa artwork",
        "authoring_tool": "tools/brasa_pilot/build.py",
        "authoring_sha256": digest(Path(__file__)),
        "source_files": {MOTION: digest(root / MOTION), ATLAS: digest(root / ATLAS)},
        "artwork": "Reuses characters/battle-creatures@1.0.0; no new pixels or spritesheets",
        "approval": "Unapproved locomotion blocking; family concept approval does not approve this gait",
        "license": "Original project animation data; original artwork provenance remains in its pinned module",
    }
    walk = {
        "schema": 1, "fps": 30, "channels": source["channels"],
        "forms": {"ember": {**{key: definition[key] for key in ("anatomy", "profile", "joints", "ground")},
                              "states": {"6": author_walk(source["channels"])}}},
    }
    write_json(folder / "walk.json", walk)
    write_json(folder / "manifest.json", {
        "schema_version": 1, "id": "characters/brasa-pilot", "version": "0.1.0",
        "status": "prototype",
        "description": "Brasa locomotion blocking for an isolated native Godot review. Not production gait.",
        "dependencies": [{"id": "characters/battle-motion", "version": "1.0.0"}],
        "provenance": provenance,
        "files": {"walk": file_record(folder / "walk.json", "walk.json", "data")},
        "metadata": {
            "form_id": "ember", "adapter": "battle-motion-v1", "walk_track": {"group": "states", "clip": "6"},
            "walk_period_seconds": 1.0, "walk_loop_endpoint_included": True,
            "ground": definition["ground"], "texture_region": atlas["regions"]["ember"],
            "required_gaps": ["Alternating planted feet and translation speed need authored locomotion",
                              "Defeat/KO pose not authored; existing celebration is not defeat",
                              "Current runtime has no creature walk playback contract",
                              "Family reference PNG transfer is blocked; no comparison to approved sheet"],
            "production_ready": False,
        },
    })


if __name__ == "__main__":
    build()
    print("Authored characters/brasa-pilot@0.1.0; runtime pins unchanged")
