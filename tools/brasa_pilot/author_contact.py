"""Author the immutable contact study from retained Image Gen pixels and atlas endpoints."""
import argparse
import shutil
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from asset_pipeline import ROOT, digest, file_record, read_json, write_json

MODULE = "characters/brasa-lifecycle"
VERSION = "1.1.0"
CELL = (512, 448)
PIVOT = (300, 400)
# Observed sole centers in the original cells, not the transparent cell pivots.
SOLES = [(229, 280), (218, 280), (158, 280), (147, 280),
         (224, 284), (198, 283), (158, 283), (148, 283)]


def author(source: Path) -> None:
    folder = ROOT / "assets" / MODULE / "versions" / VERSION
    if folder.exists():
        raise ValueError("Release already exists; author a new version")
    image = Image.open(source)
    if image.mode != "RGBA" or image.size != (1266, 1242):
        raise ValueError("Source grid must be inspected before authoring")
    (folder / "review").mkdir(parents=True)
    (folder / "review/.gdignore").touch()
    shutil.copyfile(source, folder / "review/original.png")
    scale = 339 / 261
    cells, operations = [], []
    for index in range(16):
        c, r = index % 4, index // 4
        rect = (c * image.width // 4, r * image.height // 4,
                (c + 1) * image.width // 4, (r + 1) * image.height // 4)
        raw = image.crop(rect)
        ground = SOLES[index][1] if index < 8 else [283, 283, 283, 281, 278, 279, 280, 284][index - 8]
        resized = raw.resize((round(raw.width * scale), round(raw.height * scale)), Image.Resampling.NEAREST)
        x = 60 if index < 9 else 65 if index == 9 else 75 if index == 10 else 80
        y = PIVOT[1] - round(ground * scale)
        cell = Image.new("RGBA", CELL)
        cell.alpha_composite(resized, (x, y))
        cells.append(cell)
        operations.append({"source_cell": index, "source_rect": rect,
            "nearest_scale": scale, "translation": [x, y], "sole_y": ground})
    base_path = ROOT / "assets/characters/battle-creatures/versions/1.0.0/texture.png"
    base = Image.new("RGBA", CELL)
    base.alpha_composite(Image.open(base_path).crop((40, 54, 411, 418)), (90, 50))
    old = ROOT / "assets" / MODULE / "versions/1.0.0/knockout.png"
    knockout = []
    old_scale = 339 / 301
    for i in range(4):
        raw = Image.open(old).crop((i * 362, 0, (i + 1) * 362, 362))
        raw = raw.resize((round(362 * old_scale),) * 2, Image.Resampling.NEAREST)
        cell = Image.new("RGBA", CELL)
        cell.alpha_composite(raw, (300 - round(210 * old_scale), 400 - round(324 * old_scale)))
        knockout.append(cell)
    sequences = {"walk": cells[:8], "settle": cells[8:12] + [base],
                 "knockout": knockout, "revive": [knockout[-1]] + cells[12:16] + [base]}
    files, animations = {}, {}
    for name, frames in sequences.items():
        sheet = Image.new("RGBA", (CELL[0] * 4, CELL[1] * ((len(frames) + 3) // 4)))
        for i, frame in enumerate(frames): sheet.alpha_composite(frame, (i % 4 * CELL[0], i // 4 * CELL[1]))
        sheet.save(folder / (name + ".png"))
        files[name] = file_record(folder / (name + ".png"), name + ".png", "texture")
        animations[name] = {"file": name, "frame_size": CELL, "columns": 4,
            "frames": len(frames), "fps": 7.5 if name == "walk" else 8, "pivot": PIVOT, "loop": False}
    contacts = [[60 + round(x * scale), 400] for x, y in SOLES]
    # Two stance phases: a planted pixel keeps the same world coordinate through
    # four complete poses. The visual root changes only when a new drawing appears.
    offsets = [(-138 if i < 4 else -48) + PIVOT[0] - point[0] for i, point in enumerate(contacts)]
    timelines = {name: [{"duration": 2 / 15 if name == "walk" else 0.125,
                        "offset": [offsets[i] if name == "walk" else 0, 0]}
                       for i in range(len(frames))] for name, frames in sequences.items()}
    for i, row in enumerate(timelines["walk"]):
        row.update(contact=contacts[i], support="stance_a" if i < 4 else "stance_b")
    profile = {"schema_version": 2, "forms": {"ember": {
        "walk": "walk", "ko": "knockout", "settle": "settle", "revive": "revive",
        "standing_height": 339, "source_height_ratio": 339 / 364,
        "walk_seconds": 16 / 15, "ko_seconds": 0.5,
        "timelines": timelines, "clock": "minimum_pose_dwell_no_skipped_drawings"}}}
    write_json(folder / "profile.json", profile)
    write_json(folder / "normalization.json", {"schema_version": 2, "source_sha256": digest(source),
        "shared_cell": CELL, "shared_pivot": PIVOT, "cells": operations,
        "walk_contacts": contacts, "walk_offsets": offsets,
        "idle_endpoint": {"source": str(base_path.relative_to(ROOT)), "sha256": digest(base_path),
                          "crop": [40, 54, 411, 418], "translation": [90, 50], "resampled": False},
        "ko_source": {"source": str(old.relative_to(ROOT)), "sha256": digest(old), "nearest_scale": old_scale},
        "operation": "Grid slicing, documented nearest normalization and integer translation. No painted or synthesized in-between pixels."})
    for name in ["profile", "normalization"]: files[name] = file_record(folder / (name + ".json"), name + ".json", "data")
    files["original"] = file_record(folder / "review/original.png", "review/original.png", "review")
    write_json(folder / "manifest.json", {"schema_version": 1, "id": MODULE, "version": VERSION,
        "status": "production", "description": "Brasa contact study with drawn arrival and active recovery; independent review pending.",
        "files": files, "animations": animations,
        "dependencies": [{"id": "characters/battle-creatures", "version": "1.0.0"}],
        "metadata": {"production_ready": False, "independent_review": "pending", "integration_candidate": True},
        "provenance": {"kind": "generated original animation poses", "tool": "OpenAI Image Gen",
            "recorded_date_utc": "2026-11-05", "original_output_basename": source.name,
            "original_sha256": digest(source), "reference": "Existing Brasa atlas and retained 1.0.0 pose sheet",
            "edit_history": "Original retained byte-identically. Normalization and exact atlas/KO endpoints recorded in normalization.json.",
            "license_record": "Original generated artwork for Umbral, project-owned references.",
            "review_status": "Candidate; all technical and independent visual review results recorded separately."}})
    lock = read_json(ROOT / "assets/runtime-lock.json")
    lock["bindings"]["characters/creature-lifecycle"]["version"] = VERSION
    write_json(ROOT / "assets/runtime-lock.json", lock)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    author(parser.parse_args().source)
