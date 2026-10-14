"""Linux x86_64 bootstrap. Official Godot artifacts, verified with SHA-512."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import urllib.request
import zipfile

VERSION = "4.6.3"
BASE = f"https://github.com/godotengine/godot/releases/download/{VERSION}-stable/"
ROOT = Path(os.environ.get("FERAL_STATE_ROOT", "/workspace" if Path("/workspace").exists() else str(Path.home())))
CACHE = Path(os.environ.get("XDG_CACHE_HOME", str(ROOT / ".cache"))) / "feral-hand"
DATA = Path(os.environ.get("XDG_DATA_HOME", str(ROOT / ".local/share")))
TEMPLATES = DATA / "godot/export_templates" / f"{VERSION}.stable"
CACHE.mkdir(parents=True, exist_ok=True)


def download_verified(name):
    with urllib.request.urlopen(BASE + "SHA512-SUMS.txt", timeout=60) as response:
        sums = response.read().decode()
    checksum = next(line.split()[0] for line in sums.splitlines() if line.split()[-1].lstrip("*") == name)
    archive = CACHE / name
    hasher = hashlib.sha512()
    print(f"Downloading {name}", flush=True)
    with urllib.request.urlopen(BASE + name, timeout=120) as response, archive.open("wb") as output:
        while chunk := response.read(8 * 1024 * 1024):
            hasher.update(chunk)
            output.write(chunk)
    if hasher.hexdigest() != checksum:
        archive.unlink()
        raise RuntimeError(f"SHA-512 mismatch: {name}")
    print(f"SHA-512 verified: {name}", flush=True)
    return archive


binary = shutil.which("godot")
version = subprocess.check_output([binary, "--version"], text=True).strip() if binary else ""
if not version.startswith(f"{VERSION}.stable."):
    archive = download_verified(f"Godot_v{VERSION}-stable_linux.x86_64.zip")
    destination = ROOT / ".local/bin/godot"
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as bundle:
        with bundle.open(f"Godot_v{VERSION}-stable_linux.x86_64") as source, destination.open("wb") as output:
            shutil.copyfileobj(source, output)
    destination.chmod(0o755)
    archive.unlink()
    print(f"Installed engine: {destination}")

required = ["web_nothreads_release.zip", "linux_release.x86_64", "windows_release_x86_64.exe", "windows_release_x86_64_console.exe"]
if not all((TEMPLATES / item).is_file() for item in required):
    archive = download_verified(f"Godot_v{VERSION}-stable_export_templates.tpz")
    TEMPLATES.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as bundle:
        for item in required + ["version.txt"]:
            with bundle.open(f"templates/{item}") as source, (TEMPLATES / item).open("wb") as output:
                shutil.copyfileobj(source, output)
    archive.unlink()
print(f"Godot {VERSION} and Web/Windows/Linux release templates available.")
