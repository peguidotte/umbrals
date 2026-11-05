"""Normalize the generated Brasa walk/KO cells without changing source pixels."""
from __future__ import annotations
import argparse
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from asset_pipeline import ROOT, digest, file_record, read_json, write_json

MODULE = "characters/brasa-lifecycle"
SOURCE = ROOT / "assets" / MODULE / "versions/0.2.0/review/original.png"
if not SOURCE.is_file():
    SOURCE = ROOT.parent / "generated_images/exec-90926448-5f64-4ca6-8e15-070e807370c9.png"


def author() -> None:
    folder = ROOT / "assets" / MODULE / "versions/0.2.0"
    subprocess.run(["git", "rev-parse", "--verify", "origin/main^{commit}"], cwd=ROOT, check=True, capture_output=True)
    if subprocess.run(["git", "cat-file", "-e", "origin/main:" + str(folder.relative_to(ROOT) / "manifest.json")], cwd=ROOT, capture_output=True).returncode == 0:
        raise ValueError("Published release is immutable")
    (folder / "review").mkdir(parents=True, exist_ok=True)
    (folder / "review/.gdignore").touch()
    if SOURCE.resolve() != (folder / "review/original.png").resolve():
        shutil.copyfile(SOURCE, folder / "review/original.png")
    image = Image.open(SOURCE)
    if image.mode != "RGBA" or image.size != (1448, 1086):
        raise ValueError("Inspect source grid before normalizing a different image")
    walk = Image.new("RGBA", (1448, 724))
    knockout = Image.new("RGBA", (1448, 362))
    cells = []
    for index in range(12):
        column, row = index % 4, index // 4
        rect = [column * 362, row * 362, (column + 1) * 362, (row + 1) * 362]
        cell = image.crop(rect)
        # Observed soles: y=323 in row 0, y=321 in row 1, y=304 in KO.
        shift = 0 if row == 0 else 2 if row == 1 else 19
        destination = walk if index < 8 else knockout
        destination.alpha_composite(cell, (column * 362, (row if index < 8 else 0) * 362 + shift))
        cells.append({"source_rect": rect, "translation": [0, shift], "resampled": False})
    walk.save(folder / "walk.png")
    knockout.save(folder / "knockout.png")
    profile = {"schema_version": 1, "forms": {"ember": {
        "walk": "walk", "ko": "knockout", "standing_height": 301,
        "source_height_ratio": 339 / 364, "stride_pixels": 160,
        "walk_seconds": 0.8, "ko_seconds": 0.6,
    }}}
    write_json(folder / "profile.json", profile)
    write_json(folder / "normalization.json", {"schema_version": 1, "source_sha256": digest(SOURCE), "cells": cells,
        "shared_cell": [362, 362], "shared_pivot": [210, 324],
        "operation": "Whole-cell slicing and integer translations only; original PNG copied byte-identically."})
    provenance = {"kind": "generated original animation poses", "tool": "OpenAI Image Gen",
        "model_version": "not exposed", "recorded_date_utc": "2026-11-04",
        "original_output_basename": "exec-90926448-5f64-4ca6-8e15-070e807370c9.png", "original_sha256": digest(SOURCE),
        "reference": {"module": "characters/battle-creatures", "version": "1.0.0", "region": "ember",
                      "texture_sha256": digest(ROOT / "assets/characters/battle-creatures/versions/1.0.0/texture.png")},
        "brief": "Exact Brasa identity, eight biped walk poses with alternating hind feet and four reversible KO poses, right facing, 4x3 transparent grid; preserve charcoal body, orange forepaws, amber eye and one spiral tail.",
        "edit_history": "Original retained in review/original.png. Runtime cells sliced and integer translated; no resampling, repainting or alpha cleanup.",
        "license_record": "Original generated artwork for Umbral using project-owned reference; no third-party game art.",
        "review_status": "Candidate; native-size movement and independent review pending."}
    files = {"walk": file_record(folder / "walk.png", "walk.png", "texture"),
             "knockout": file_record(folder / "knockout.png", "knockout.png", "texture"),
             "profile": file_record(folder / "profile.json", "profile.json", "data"),
             "normalization": file_record(folder / "normalization.json", "normalization.json", "data"),
             "original": file_record(folder / "review/original.png", "review/original.png", "review")}
    animations = {name: {"file": name, "frame_size": [362, 362], "columns": 4,
                         "frames": count, "fps": fps, "pivot": [210, 324], "loop": loop}
                  for name, count, fps, loop in [("walk", 8, 10, True), ("knockout", 4, 6.666666667, False)]}
    write_json(folder / "manifest.json", {"schema_version": 1, "id": MODULE, "version": "0.2.0", "status": "prototype",
        "description": "Brasa original biped locomotion and reversible incapacitation poses.",
        "files": files, "provenance": provenance, "animations": animations,
        "dependencies": [{"id": "characters/battle-creatures", "version": "1.0.0"}],
        "metadata": {"production_ready": False, "independent_review": "pending"}})


def promote(review_record: str) -> None:
    source = ROOT / "assets" / MODULE / "versions/0.2.0"
    folder = source.parent / "1.0.0"
    if not (ROOT / review_record).is_file():
        raise ValueError("Promotion requires a concrete native review record")
    if folder.exists():
        raise ValueError("Promotion target already exists")
    shutil.copytree(source, folder)
    manifest = read_json(folder / "manifest.json")
    manifest.update(version="1.0.0", status="production")
    manifest["provenance"]["review_status"] = "Native-size motion reviewed for integration; independent PR review still pending."
    manifest["metadata"].update(review_record=review_record, review_sha256=digest(ROOT / review_record),
                                production_ready=False, integration_candidate=True)
    write_json(folder / "manifest.json", manifest)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--promote", metavar="REVIEW_RECORD")
    args = parser.parse_args()
    promote(args.promote) if args.promote else author()
