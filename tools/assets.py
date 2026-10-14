"""Asset release maintenance. No command selects 'latest' for the game."""
import argparse
from pathlib import Path
import re
import shutil
import sys

from asset_pipeline import (ROOT, AssetError, VERSION, build, file_record,
                            load_releases, read_json, validate, write_json)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT, help="Project root (defaults to this checkout)")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("build", help="Rebuild catalog, provenance and Godot constants")
    new = commands.add_parser("new", help="Create an unpublished module, with no fabricated artwork")
    new.add_argument("id")
    new.add_argument("--version", default="1.0.0")
    new.add_argument("--description", required=True)
    check = commands.add_parser("validate", help="Validate schemas, hashes, references, atlases and pins")
    check.add_argument("--base-ref", help="Also reject edits to releases present in this Git commit")
    bump = commands.add_parser("bump", help="Copy an existing release into a new immutable version")
    bump.add_argument("id")
    bump.add_argument("--from", required=True, dest="previous")
    bump.add_argument("--to", required=True, dest="version")
    bump.add_argument("--change", required=True)
    refresh = commands.add_parser("refresh", help="Rehash an unpublished release after editing")
    refresh.add_argument("id")
    refresh.add_argument("version")
    refresh.add_argument("--base-ref", default="origin/main")
    args = parser.parse_args(argv)
    root = args.root.resolve()
    try:
        if args.command == "build":
            build(root)
            print("Asset catalog, provenance and Godot bindings generated.")
        elif args.command == "validate":
            import json
            print(json.dumps(validate(root, base_ref=args.base_ref)))
        elif args.command == "new":
            if not re.fullmatch(r"[a-z][a-z0-9-]*/[a-z][a-z0-9-]*", args.id) or not VERSION.fullmatch(args.version):
                raise AssetError("Use domain/slug and a canonical SemVer")
            if args.id.split("/")[0] not in read_json(root / "assets/domains.json")["domains"]:
                raise AssetError("Register the domain in assets/domains.json first")
            target = root / "assets" / args.id / "versions" / args.version / "manifest.json"
            if target.parent.exists():
                raise AssetError("Release already exists; use bump for the next version")
            write_json(target, {"schema_version": 1, "id": args.id, "version": args.version,
                               "status": "draft", "description": args.description,
                               "provenance": {"kind": "pending authoring; record source and license before promotion"},
                               "files": {}, "dependencies": []})
            build(root)
            print(f"Created {args.id}@{args.version} as an empty draft. Add real files and provenance.")
        elif args.command == "bump":
            releases = load_releases(root)
            if not VERSION.fullmatch(args.version) or tuple(map(int, args.version.split("."))) <= tuple(map(int, args.previous.split("."))):
                raise AssetError("The destination must be a newer canonical SemVer")
            previous, data = releases[(args.id, args.previous)]
            destination = root / "assets" / args.id / "versions" / args.version
            if destination.exists():
                raise AssetError("Version already exists; releases are never overwritten")
            shutil.copytree(previous.parent, destination, ignore=shutil.ignore_patterns("*.import", "*.uid"))
            data["version"] = args.version
            data["status"] = "draft"
            data["changes"] = args.change
            write_json(destination / "manifest.json", data)
            build(root)
            print(f"Created {args.id}@{args.version} as draft. Runtime pins are unchanged.")
        elif args.command == "refresh":
            path, data = load_releases(root)[(args.id, args.version)]
            # Check existence in the base, even when the author has not edited it yet.
            import subprocess
            base = subprocess.run(["git", "rev-parse", "--verify", args.base_ref + "^{commit}"], cwd=root, capture_output=True)
            if base.returncode:
                raise AssetError(f"Cannot verify immutable base {args.base_ref}")
            exists = subprocess.run(["git", "cat-file", "-e", args.base_ref + ":" + path.relative_to(root).as_posix()], cwd=root, capture_output=True)
            if exists.returncode == 0:
                raise AssetError("Published release: bump its version before refreshing hashes")
            for role, item in list(data["files"].items()):
                from asset_pipeline import inside
                refreshed = file_record(inside(path.parent, item["path"]), item["path"], item["kind"], item.get("provenance"))
                if "technical" in item:
                    item["technical"].update(refreshed.get("technical", {}))
                    refreshed["technical"] = item["technical"]
                data["files"][role] = refreshed
            write_json(path, data)
            build(root)
            print(f"Refreshed unpublished {args.id}@{args.version}; validate before committing.")
    except (AssetError, KeyError, ValueError, OSError) as error:
        print(f"asset error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
