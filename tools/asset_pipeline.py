"""Canonical asset catalog, exact runtime pins, integrity and immutable releases."""
from __future__ import annotations

import hashlib
import json
import re
import subprocess
from pathlib import Path, PurePosixPath
from typing import Any

from jsonschema import Draft202012Validator
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
VERSION = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")
RELEASE = re.compile(r"^assets/([a-z][a-z0-9-]*/[a-z][a-z0-9-]*)/versions/([^/]+)/")


class AssetError(ValueError):
    pass


def read_json(path: Path) -> Any:
    def unique(pairs: list) -> dict:
        result = {}
        for key, value in pairs:
            if key in result:
                raise AssetError(f"Duplicate JSON key {key!r}: {path}")
            result[key] = value
        return result
    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique,
                      parse_constant=lambda value: (_ for _ in ()).throw(AssetError(f"Non-finite JSON number: {value}")))


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def inside(base: Path, relative: str) -> Path:
    parts = PurePosixPath(relative)
    if not relative or "\\" in relative or parts.is_absolute() or any(p in {".", ".."} for p in relative.split("/")):
        raise AssetError(f"Unsafe asset path: {relative!r}")
    path = base / relative
    if not path.resolve().is_relative_to(base.resolve()) or any(p.is_symlink() for p in [path, *path.parents] if p != base.parent):
        raise AssetError(f"Asset path escapes its release or uses a symlink: {relative}")
    return path


def file_record(path: Path, relative: str, kind: str, provenance: dict | None = None) -> dict:
    result = {"path": relative, "kind": kind, "sha256": digest(path), "bytes": path.stat().st_size}
    if path.suffix.lower() in {".png", ".webp", ".gif"}:
        with Image.open(path) as image:
            result["technical"] = {"dimensions": list(image.size), "mode": image.mode,
                                   "frames": image.n_frames, "alpha": "A" in image.getbands() or "transparency" in image.info}
    if provenance:
        result["provenance"] = provenance
    return result


def load_releases(root: Path = ROOT) -> dict[tuple[str, str], tuple[Path, dict]]:
    domains = read_json(root / "assets/domains.json")["domains"]
    releases = {}
    validators = {}
    for path in sorted((root / "assets").glob("*/*/versions/*/manifest.json")):
        release = read_json(path)
        schema_version = release.get("schema_version")
        if type(schema_version) is not int or schema_version < 1:
            raise AssetError(f"Invalid schema version in {path}")
        if schema_version not in validators:
            schema_path = root / f"assets/schemas/module-v{schema_version}.schema.json"
            if not schema_path.is_file():
                raise AssetError(f"Unsupported asset schema v{schema_version}")
            validators[schema_version] = Draft202012Validator(read_json(schema_path))
        validator = validators[schema_version]
        errors = sorted(validator.iter_errors(release), key=lambda e: str(e.path))
        if errors:
            raise AssetError(f"{path.relative_to(root)}: {errors[0].message}")
        key = (release["id"], release["version"])
        expected = root / "assets" / release["id"] / "versions" / release["version"] / "manifest.json"
        if path != expected or key in releases or release["id"].split("/")[0] not in domains:
            raise AssetError(f"Release identity/domain does not match its directory: {path}")
        if not release["files"] and release["status"] != "draft":
            raise AssetError(f"Non-draft release has no files: {key}")
        releases[key] = (path, release)
    if not releases:
        raise AssetError("No asset releases found")
    return releases


def generated_documents(root: Path = ROOT, releases: dict | None = None) -> tuple[dict, dict, str]:
    releases = releases if releases is not None else load_releases(root)
    modules: dict = {}
    files = []
    for (asset_id, version), (path, release) in sorted(releases.items()):
        modules.setdefault(asset_id, {"versions": {}})["versions"][version] = {
            "manifest": path.relative_to(root).as_posix(), "sha256": digest(path), "status": release["status"]}
        for role, item in sorted(release["files"].items()):
            files.append({"id": f"{asset_id}@{version}:{role}", "module": asset_id, "version": version,
                          "role": role, "path": (path.parent / item["path"]).relative_to(root).as_posix(),
                          "sha256": item["sha256"], "bytes": item["bytes"], "status": release["status"],
                          "source": item.get("provenance", release["provenance"]),
                          "technical": item.get("technical", {}), "kind": item["kind"]})
    catalog = {"schema_version": 1, "modules": modules}
    provenance = {"schema_version": 2, "generated_by": "tools/assets.py build", "assets": files}
    lock = read_json(root / "assets/runtime-lock.json")
    paths = []
    for binding, ref in sorted(lock["bindings"].items()):
        key = (ref["id"], ref["version"])
        if key not in releases:
            raise AssetError(f"Unknown pinned release for {binding}: {key}")
        path, release = releases[key]
        if release["status"] != "production":
            raise AssetError(f"Runtime binding {binding} points to {release['status']} art")
        if ref["file"] not in release["files"]:
            raise AssetError(f"Unknown file role for {binding}: {ref['file']}")
        file = release["files"][ref["file"]]
        if file["kind"] not in {"texture", "audio", "font"}:
            raise AssetError(f"Runtime binding {binding} is not a loadable Godot asset")
        name = re.sub("[^A-Z0-9]", "_", binding.upper())
        paths.append((name, "res://" + (path.parent / file["path"]).relative_to(root).as_posix()))
    if len({name for name, _ in paths}) != len(paths):
        raise AssetError("Runtime binding names collide after GDScript normalization")
    gd = '# Generated by tools/assets.py build from runtime-lock.json. Do not edit.\nextends RefCounted\n'
    gd += "".join(f'const {name}: String = {json.dumps(path)}\n' for name, path in paths)
    gd += "\nconst PATHS: Dictionary = {\n"
    gd += "".join(f'\t{json.dumps(binding)}: {re.sub("[^A-Z0-9]", "_", binding.upper())},\n' for binding in sorted(lock["bindings"]))
    gd += "}\n"
    return catalog, provenance, gd


def build(root: Path = ROOT) -> None:
    catalog, provenance, gd = generated_documents(root)
    write_json(root / "assets/catalog.json", catalog)
    write_json(root / "assets/asset-manifest.json", provenance)
    target = root / "scripts/assets/binding_paths.gd"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(gd, encoding="utf-8")


def immutable_changes(root: Path, base_ref: str) -> list[str]:
    def git(*args: str) -> str:
        result = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True)
        if result.returncode:
            raise AssetError(result.stderr.strip() or f"Cannot read Git base {base_ref}")
        return result.stdout
    git("rev-parse", "--verify", base_ref + "^{commit}")
    base_files = git("ls-tree", "-r", "--name-only", base_ref, "assets").splitlines()
    existing = {match.group(0) for path in base_files
                if (match := RELEASE.match(path))}
    schemas = {path for path in base_files if path.startswith("assets/schemas/")}
    changes = set(git("diff", "--no-renames", "--name-only", base_ref, "--", "assets").splitlines())
    changes.update(git("ls-files", "--others", "--exclude-standard", "--", "assets").splitlines())
    return sorted(path for path in changes if path in schemas or ((match := RELEASE.match(path)) and match.group(0) in existing))


def validate(root: Path = ROOT, base_ref: str | None = None, check_generated: bool = True) -> dict:
    releases = load_releases(root)
    declared = set()
    texture_bytes = 0
    for key, (manifest_path, release) in releases.items():
        base = manifest_path.parent
        local = set()
        for role, item in release["files"].items():
            path = inside(base, item["path"])
            if item["path"] == "manifest.json" or path in local or not path.is_file():
                raise AssetError(f"Missing, duplicate or recursive file in {key}: {item['path']}")
            local.add(path)
            declared.add(path)
            if path.stat().st_size != item["bytes"] or digest(path) != item["sha256"]:
                raise AssetError(f"Integrity mismatch in {key}: {item['path']}")
            if item["bytes"] > 16 * 1024**2:
                raise AssetError(f"File exceeds the 16 MiB source budget: {path}")
            if path.suffix.lower() == ".png":
                with Image.open(path) as image:
                    technical = item.get("technical", {})
                    if technical.get("dimensions") != list(image.size) or technical.get("mode") != image.mode:
                        raise AssetError(f"Image metadata differs: {path}")
                    if item["kind"] == "texture" and image.mode == "RGBA" and max(image.size) > 4096:
                        raise AssetError(f"RGBA atlas exceeds 4096: {path}")
                    texture_bytes += image.width * image.height * len(image.getbands())
            if not item.get("provenance", release["provenance"]):
                raise AssetError(f"Missing provenance: {path}")
        actual = {p for p in base.rglob("*") if p.is_file() and p.name not in {"manifest.json", ".gdignore"} and not p.name.endswith((".import", ".uid"))}
        if actual != local:
            raise AssetError(f"Untracked files inside {key}: {actual ^ local}")
        for dep in release["dependencies"]:
            if (dep["id"], dep["version"]) not in releases:
                raise AssetError(f"Unresolved dependency in {key}: {dep}")
            if release["status"] == "production" and releases[(dep["id"], dep["version"])][1]["status"] != "production":
                raise AssetError(f"Production release depends on non-production art in {key}: {dep}")
        for name, anim in release.get("animations", {}).items():
            w, h = anim["frame_size"]
            if not (0 <= anim["pivot"][0] < w and 0 <= anim["pivot"][1] < h):
                raise AssetError(f"Animation {name} has an out-of-cell pivot")
            pages = anim.get("pages", [anim])
            if sum(page["frames"] for page in pages) != anim["frames"]:
                raise AssetError(f"Animation {name} page counts differ from its frame count")
            if any("low_file" in page for page in pages) and not all("low_file" in page for page in pages):
                raise AssetError(f"Animation {name} has an incomplete low-quality page set")
            for page in pages:
                item = release["files"].get(page["file"])
                if not item or item["kind"] != "texture":
                    raise AssetError(f"Animation {name} has an unknown texture page in {key}")
                expected = (w * anim["columns"], h * ((page["frames"] + anim["columns"] - 1) // anim["columns"]))
                with Image.open(inside(base, item["path"])) as image:
                    if image.size != expected:
                        raise AssetError(f"Animation {name} grid does not fit its atlas")
                    if image.mode != "RGBA" or image.getchannel("A").getextrema()[0] != 0:
                        raise AssetError(f"Animation {name} needs a transparent RGBA atlas")
                if "low_file" in page:
                    low = release["files"].get(page["low_file"])
                    if not low or w % 2 or h % 2:
                        raise AssetError(f"Animation {name} needs an even low-quality cell grid")
                    with Image.open(inside(base, low["path"])) as image:
                        if image.size != (expected[0] // 2, expected[1] // 2) or image.mode != "RGBA":
                            raise AssetError(f"Animation {name} low-quality grid differs")
        for name, performance in release.get("performances", {}).items():
            for role in ("charge", "release", "projectile", "impact", "trail", "takeoff"):
                if role in performance and performance[role] not in release.get("animations", {}):
                    raise AssetError(f"Performance {name} references an unknown local animation: {role}")
            actor = performance.get("actor")
            if actor:
                dep = {"id": actor["id"], "version": actor["version"]}
                if dep not in release["dependencies"] or (actor["id"], actor["version"]) not in releases:
                    raise AssetError(f"Performance {name} lacks its explicit character dependency")
                if actor["animation"] not in releases[(actor["id"], actor["version"])][1].get("animations", {}):
                    raise AssetError(f"Performance {name} references an unknown character animation")
    visited, visiting = set(), set()
    def visit(key: tuple) -> None:
        if key in visiting:
            raise AssetError(f"Cyclic asset dependency: {key}")
        if key in visited:
            return
        visiting.add(key)
        for dep in releases[key][1]["dependencies"]:
            visit((dep["id"], dep["version"]))
        visiting.remove(key)
        visited.add(key)
    for key in releases:
        visit(key)
    all_payload = {p for p in (root / "assets").glob("*/*/versions/*/**/*") if p.is_file() and p.suffix.lower() in {".png", ".svg", ".wav", ".ttf", ".webp", ".gif", ".mp4"}}
    if not all_payload <= declared:
        raise AssetError(f"Assets without a module manifest: {all_payload - declared}")
    # Reject obsolete flat art rather than silently leaving two sources of truth.
    for p in (root / "assets").rglob("*"):
        if p.is_file() and p.suffix.lower() in {".png", ".svg", ".wav", ".ttf", ".webp", ".gif", ".mp4"} and p not in declared:
            raise AssetError(f"Unowned source asset: {p.relative_to(root)}")
    if check_generated:
        catalog, provenance, gd = generated_documents(root, releases)
        for name, expected in [("catalog.json", catalog), ("asset-manifest.json", provenance)]:
            if read_json(root / "assets" / name) != expected:
                raise AssetError(f"Stale generated {name}; run python tools/assets.py build")
        if (root / "scripts/assets/binding_paths.gd").read_text() != gd:
            raise AssetError("Stale generated Godot bindings; run python tools/assets.py build")
    if base_ref:
        changed = immutable_changes(root, base_ref)
        if changed:
            raise AssetError(f"Published release is immutable; create a new version: {changed[:5]}")
    return {"suite": "asset_modules", "releases": len(releases), "files": len(declared),
            "texture_source_bytes": texture_bytes, "failed": 0, "immutability_base": base_ref}
