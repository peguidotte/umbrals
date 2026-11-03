"""Source identities and task inputs. Standard library only; no rendering imports."""
import fnmatch
import hashlib
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
IGNORED = {'.godot', 'builds', 'test-results', 'artifacts', '__pycache__', '.git'}


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def source_manifest(root=ROOT):
    records = {}
    for current, directories, names in os.walk(root):
        directories[:] = sorted(name for name in directories if name not in IGNORED)
        for name in sorted(names):
            path = Path(current) / name
            if name.endswith(('.uid', '.import', '.pyc')):
                continue
            records[path.relative_to(root).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    return {'sha256': digest(records), 'files': records}


def matches(path, patterns):
    return any(fnmatch.fnmatchcase(path, pattern) for pattern in patterns)


def file_hashes(folder):
    return {p.relative_to(folder).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(folder.rglob('*')) if p.is_file() and p.name != '.gdignore'}
