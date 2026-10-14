"""Package current exports; validate expected entry points and preserve provenance."""
import hashlib
import json
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
version = re.search(r'config/version="([^"]+)"', (ROOT / "project.godot").read_text()).group(1)
manifest = {}
entry_points = {"web": "index.html", "windows": "Umbral.exe", "linux": "Umbral.x86_64"}
for target, entry in entry_points.items():
    folder = ROOT / "builds" / target
    if not (folder / entry).is_file():
        raise RuntimeError(f"Export first: {target}")
    files = [p for p in folder.rglob("*") if p.is_file()
             and not p.name.endswith(".tmp") and not p.name.startswith("FeralHand")]
    files = [p for p in files if p.suffix != '.import']
    archive = ROOT / "builds" / f"Umbral-{version}-{target}.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as out:
        for file in files:
            out.write(file, file.relative_to(folder))
        out.write(ROOT / "assets/FONT-LICENSE.txt", "FONT-LICENSE.txt")
        out.write(ROOT / "assets/README.md", "ASSET-PROVENANCE.md")
        out.write(ROOT / "assets/asset-manifest.json", "ASSET-MANIFEST.json")
        out.writestr("LEIA-ME.txt",
            f"Umbral: Ecos do Bosque {version}\n\n"
            "Windows: execute Umbral.exe.\n"
            "Linux: chmod +x Umbral.x86_64 e execute.\n"
            "Web: nesta pasta, execute python -m http.server 8000 e abra http://localhost:8000.\n"
            "O build Web precisa de HTTP; abrir index.html diretamente não funciona.\n\n"
            "Escolha Iniciar expedição. Clique nos poderes ou use 1–6. Espaço conjura; R troca.\n"
            "C inspeciona; Esc pausa/volta. Setas/Tab navegam e Enter ativa o item em foco.\n"
            "Controle: A seleciona, X conjura, RB troca, Y inspeciona, B volta.\n"
            "Opções: música, efeitos, movimento reduzido, flashes e texto ampliado.\n"
            "Até 3 poderes e 3 energia por rodada. Escudo absorve a intenção anunciada.\n"
            "Trait é da espécie. Passiva é do indivíduo. Evolução preserva a passiva e abre um poder novo.\n"
            "Capture, evolua ou substitua para construir seu time de até 3 Umbrals.\n\n"
            "Build Windows sem assinatura digital. Steamworks ainda não integrado.\n")
    with archive.open("rb") as file:
        digest = hashlib.file_digest(file, "sha256").hexdigest()
    with zipfile.ZipFile(archive) as check:
        if check.testzip() is not None or entry not in check.namelist():
            raise RuntimeError(f'Archive validation failed: {archive.name}')
    manifest[archive.name] = {"version": version, "bytes": archive.stat().st_size, "sha256": digest}
    print(archive.name, archive.stat().st_size, "bytes")
(ROOT / "builds/manifest.json").write_text(json.dumps(manifest, indent=2))
