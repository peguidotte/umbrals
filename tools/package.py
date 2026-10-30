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
            "Expedição com bifurcação e chefe; critérios humanos de 0.4 continuam em playtest.\n"
            "No mapa, selecione e confirme o caminho. Continuar retoma o estado confirmado sem rerrolar.\n"
            "Treino de batalha mantém o percurso curto anterior e preserva a expedição salva.\n"
            "Escolha seu primeiro vínculo entre as quatro espécies. Clique nos poderes ou use 1–6; clique nas criaturas para escolher alvos.\n"
            "Espaço conjura; R resortear passa a rodada inteira, recebendo as ações inimigas.\n"
            "P abre o plano, Q/E muda o alvo, Backspace limpa os comandos.\n"
            "Clique em Compra/Descarte para consultar as pilhas.\n"
            "PLANO permite inspecionar por toque e conjurar; RESUMO explica a última rodada.\n"
            "Capturar permite Campo ou Reserva; uma vaga livre é sugerida e só confirma ao aceitar.\n"
            "C inspeciona; Esc pausa/volta. Setas/Tab navegam e Enter ativa o item em foco.\n"
            "Controle: A seleciona, X conjura, RB resortear, Y inspeciona, LB abre o plano, B volta.\n"
            "Opções: música, efeitos, movimento reduzido, flashes, texto ampliado e informação inimiga.\n"
            "Mão base de 6 cartas e 3 ações compartilhadas; custos variam por poder.\n"
            "HP individual; a velocidade intercala aliados e inimigos. Água antes de raio pode formar combo.\n"
            "Semeado + Bosque/Água/Fogo: escudo/cura/Queima. Interferência enfraquece o próximo ataque.\n"
            "Natureza do golpe e resistências são explícitas; C explica condições e fontes.\n"
            "Comece com 1 ativo; até 6 no time e no máximo 3 em campo, por escolha.\n"
            "Reservas ficam fora da compra. Trocas custam 1 ação e só executam ao Conjurar.\n"
            "Quem entra recebe o golpe na vaga e contribui cartas na próxima compra normal.\n"
            "Cartas de incapacitados continuam bloqueadas; reanimar permite agir na próxima rodada.\n"
            "Abra a mochila para planejar consumíveis externos ao baralho.\n"
            "Trait é da espécie; passiva é do indivíduo. Evolução melhora as cópias existentes.\n"
            "Percurso curto: combate/recompensa ou descanso antes do chefe. Mapa inicial fixo e save versionado.\n"
            "Lojas, aprendizado e relíquias adquiríveis ainda planejados.\n\n"
            "Build Windows sem assinatura digital. Steamworks ainda não integrado.\n")
    with archive.open("rb") as file:
        digest = hashlib.file_digest(file, "sha256").hexdigest()
    with zipfile.ZipFile(archive) as check:
        if check.testzip() is not None or entry not in check.namelist():
            raise RuntimeError(f'Archive validation failed: {archive.name}')
    manifest[archive.name] = {"version": version, "bytes": archive.stat().st_size, "sha256": digest}
    print(archive.name, archive.stat().st_size, "bytes")
(ROOT / "builds/manifest.json").write_text(json.dumps(manifest, indent=2))
