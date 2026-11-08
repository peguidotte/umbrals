# Assets

## Electric family — V05-ART-02

`characters/electric-family@2.0.0` contains new Nisca/Niscor sprites, separately
generated views for each side, original anatomical mesh tracks, in-place gait,
hurt/KO and attached attack origins. It is the proposed production target of
the existing `umbrals/volt` and `umbrals/tempestral` bindings in the draft branch.
It replaces their old beetle representation without changing content IDs or stats.
The official Library reference and both original generated PNGs retain their
bytes/metadata under the releases' `review/` folders. The reference hash and
normalization are recorded in the manifests. Runtime PNGs use explicit alpha,
nearest filtering and grounded pivots. These are mesh animations, not redrawn
frame sequences. Final human art approval remains open.

`characters/electric-adults@1.0.0` is an **unpinned prototype**: Auravel with wings
and Zuldar as a biped with attached blue quills. No evolution, stats, rig, attack
origin or playable adult is claimed. See [scope and handoff](../docs/electric-family-v05-art02.md).

Referências conceituais de personagens e Umbrais ficam no
[acervo documental](../docs/references/identidades/README.md), com origem,
hashes e limites de aprovação por prancha. São fontes para produção posterior,
separadas dos módulos e do manifesto gerado de runtime; não representam sprites
ou animações prontos. O mineral é proposta futura e a água tem aprovação restrita
ao painel da companheira indicado no acervo.

Asset modules live at `<domain>/<slug>/versions/<semver>/`. Each release owns a manifest with file roles, provenance, hashes, animation contracts and exact dependencies. Demo actors and earlier attack studies remain prototypes; the approved battle performances have explicit production pins.

Read [the architecture and workflow](../docs/assets/README.md) before adding or evolving art. `runtime-lock.json` pins production art; `catalog.json`, `asset-manifest.json` and the Godot binding paths are generated with `python tools/assets.py build`. Validate with `python tools/assets.py validate --base-ref origin/main`.

Domains: attacks, characters, umbrals, traits, passives, items, audio, world, fonts and ui. Character motion and attack effects are separate reusable modules. Empty domains are reserved for future assets.

Original source art remains original to the project. Editable vector/audio sources are in `tools/generate_assets.py` and `tools/generate_audio.py`; VFX sources and references are in `tools/asset_authoring/`. Font licenses are preserved both here and in the font module. Original generated forest PNG metadata is retained. Archived pre-migration inventories and the exact migration map are in `docs/assets/`.

## Battle assets

`attacks/woodland-elements@1.0.0` is a prototype VFX family generated with
OpenAI Image Gen (`exec-5845b7c1-b024-4120-9ca6-18c891a321c0`). Its original RGBA
PNG retains embedded metadata. Sixteen transparent clips are procedurally animated
from that atlas, with source ownership in `tools/asset_authoring/attack_studies_v4.js`
and export in `export_element_clips.py`. No third-party game art was used.
The fifteen standalone choreography previews use this family. The prototype is
preserved independently of the production version below.

`attacks/woodland-elements@1.1.0` integrates the user-approved revision 5 through
the production binding `attacks/battle-performances`. Exact dependencies pin
`characters/battle-motion@1.0.0` (normalized skeletal tracks and calibrated
sockets for eight forms) and `audio/battle-performances@1.0.0` (fifteen original
stereo performances). The original character PNG bytes are unchanged. Native
Godot meshes animate those pixels; these are not hand-redrawn pose sequences.
See [the runtime integration](../docs/battle-motion-v04-08a.md).

The original first-stage and evolved battle atlases and grounding maps are in `characters/battle-creatures` and `characters/battle-evolved`; their PNG bytes are preserved. The maps use the module texture paths. The original battle provenance and prompts are retained alongside the first atlas. `world/battle-clearing-depth` is the reviewed wide arena, while `world/battle-clearing` retains the earlier artwork. Water portraits, power icons and the backpack are original project vectors. The original v0.4 inventory, including generation briefs, source hashes and review context, is archived in `docs/assets/original-v0.4-manifest.json`.


### UI V04-UX-05A

Esta fatia reutiliza os módulos já fixados do catálogo: retratos dos atlas de
batalha, ícones de poderes e `world/moonlit-clearing`. O reenquadramento e o
tingimento do mapa acontecem no runtime; os PNGs originais e metadados não
foram alterados. Cristais de custo/ações e decoração de trilha são geometria
original em `scripts/ui/action_meter.gd`, `power_card.gd` e `expedition_trail.gd`.
Não há imagem gerada nova, dependência externa nova ou alteração de versão/pin
nesta rodada. A arte dedicada de poderes e marcos permanece trabalho posterior.

## Selected title composition — V04-UX-05B

`ui/title-menu@1.0.0` preserves the user-selected Image Gen PNG byte-for-byte.
The production binding is explicit. Authored lettering/icons remain in the image;
real Godot buttons supply input/focus. Localized shader lighting and tap energy
are presentation only. See its manifest for generation identity and source SHA.

## Title layers — V04-UX-05C

`ui/title-menu@1.0.0` remains immutable and supplies the original button/card pixels.
`world/title-forest@1.0.0` is its clean forest plate (Image Gen edit
`exec-eec7c2ef-f5be-4941-89d7-d4ac88254736`), and `ui/title-logo@1.0.0` is the
previously approved transparent wordmark (`exec-5bf7018c-2293-49c2-a8cd-1e624c454153`).
Both originals retain their embedded metadata; hashes and filtering are recorded
in the module manifests. Card masks, logo region, button chamfers and transforms
are runtime presentation. Water/insect/crystal/card cues are original deterministic
synthesis in `scripts/ui/audio.gd`, using bounded voices and existing Music/UI buses.

- Gold title/codex environment: `world/gold-forest@1.0.0`, original Image Gen
  clean forest plate derived from the selected menu composition. Original PNG
  and embedded metadata preserved; no text or creatures painted into the plate.
  Native UI and existing creature atlases are composed separately at runtime.
- `ui/gold-frame@1.0.0`: transparent original Image Gen botanical frame, original
  PNG retained; sliced only at runtime for controls and outer decoration.
- `fonts/cormorant@1.0.0`: Cormorant Garamond from Google Fonts, SIL OFL 1.1;
  original font and license included, used only by gold presentation.
- `ui/gold-approved@1.0.0`: approved menu/codex originals plus text-free scene/UI
  templates, preserved with per-file generation provenance. Runtime atlas regions
  retain brand, ornaments, portrait illustrations and fixed caption plates. Each
  interactive plate is a separate native control; discovery data is not baked in.

## Refúgio lateral — V05-UX-03

`world/refuge-lateral@1.0.0` é um cenário original sem atores embutidos, gerado
com OpenAI Image Gen usando o menu do próprio jogo como referência visual.
`characters/refuge-traveler@1.0.0` contém um atlas original separado, com repouso
e seis poses de caminhada selecionadas, regiões/pivôs explícitos e escala fixa.
O atlas de criaturas existente orientou o acabamento; os Umbrais não ganharam
animações de caminhada por esta alteração. PNGs originais mantêm bytes e
metadados; manifests registram origem, hashes e referências. A fonte Cormorant
e sua licença existente são reutilizadas. Ver `docs/refuge-v05-ux03.md`.

## Aquatic presentation pilot

`characters/aquatic-family@1.0.0` contains untouched generated body/sphere PNGs
and their prompts/reference identity in `source.json`. Lonlon and Lonaro are
bound through the battle renderer. Final-form bodies, reverse views and the
living sphere remain source studies, not completed playable animations. See
[scope and evidence](../docs/aquatic-pilot-v04-09b.md).

## Casa inicial de Pietro — V05-UX-05

Histórico da primeira tentativa, superado pela revisão contínua abaixo:

`world/pietro-house@1.0.0` fornece três regiões de cenário (quarto de Pietro,
cozinha/escada e quarto da mãe) em um atlas original sem atores. O PNG da primeira
geração permanece em `review/`; o PNG de runtime corrige a vista pela porta do
quarto para um corredor interno. Os dois originais mantêm bytes/metadados.
`world/refuge-lateral@1.1.0` acrescenta passagens pintadas para quarto e cozinha,
preservando composição/móveis da sala e saída externa; 1.0.0 continua intacta.
As imagens usam a própria sala anterior como referência de família. O atlas
do viajante continua separado e inalterado; tint/apoio e a breve saída da cama
são apresentação no motor. Os manifestos distinguem uso no runtime de aprovação
estética por Pedro. [Escopo e limites](../docs/house-v05-ux05.md).

### Revisão contínua da casa de Pietro

`world/pietro-house-continuous@1.0.0` substitui a seleção por cômodo por uma única
pintura de casa, sem atores ou escada embutida. `characters/pietro-home@1.0.0`
fornece ator separado de pele mais clara e roupa inicial azul/dourada, provisório:
a referência Library aprovada não pôde ser transferida oficialmente. Os PNGs
gerados e seus metadados estão preservados byte a byte. A escala e os pivôs são
dados; degraus/corrimão e oclusão são geometria nativa. As releases anteriores
continuam imutáveis. Ver [escopo e limites](../docs/house-v05-ux05.md).

### Pietro a partir do conceito — V05-ART-01

`characters/pietro-home@2.0.0` usa a referência aprovada da Library, materializada
oficialmente e inspecionada neste executor antes da geração. Pele clara, cabelo
escuro ondulado, rosto mais contido e lenço ocre aproximam o ator do conceito.
O PNG original transparente e a referência permanecem intactos, com hashes,
identidade Library, pivôs e escala explícitos. Repouso e seis poses de caminhada
usam o consumidor da casa existente. O único pin alterado é o do protagonista;
nenhum script de geometria, movimento ou save mudou. Aprovação estética do
sprite continua pendente. Ver [referência, integração e limites](../docs/pietro-v05-art01.md).

## Foli initial-form pilot — V05-ART-02F

`characters/foli-pilot@1.0.0` preserves the original transparent Image Gen
cutout (`exec-7dccbeb5-ce85-494c-997a-2ef723555560`) and its own anatomical
mesh tracks. The only changed runtime binding is `umbrals/moss`; historical
modules remain intact. Reference originals and Library provenance live under
`docs/references/creatures/foli/`. This draft selects the cutout for visual
review; it has no authored walk or persistent KO pose. Folife still uses the
historical art. See [scope and evidence](../docs/foli-pilot-v05-art-02f.md).

### Foli/Folife com lifecycle — V05-ART-02G/H

As descrições do piloto inicial acima são históricas. Esta união local seleciona
`characters/foli-pilot@1.0.0` e `characters/folife-pilot@1.0.0` para os dois
retratos, com oito poses de caminhada e quatro de KO em módulos próprios de
lifecycle `1.0.0`. Os pins por forma compõem com o adaptador compartilhado;
nenhum asset/pin de Brasa é incorporado por esta união. O Pietro 2.0.0 e a casa
permanecem selecionados. As referências originais ficam excluídas da exportação.
Revisão técnica permite experimento em draft; não há aprovação estética nem
família completa. Ver os escopos de Foli/Folife e os pareceres independentes.
Auravel/Zuldar: `characters/electric-adults@2.0.0` contém originais referenciados
à família aprovada, duas vistas, rigs e poses desenhadas de KO. Arte/movimento
continuam candidatos à revisão; [escopo e limites](../docs/electric-adults-v05-art03.md).
`characters/electric-family@2.1.0` move a origem secundária do Niscor para pixels
opacos de um espinho preso; releases anteriores permanecem íntegros.


`ui/living-title@2.0.0` corrige a candidata do menu: fontes canônicas de
personagens são consultadas nos bindings reais do jogo; os atlas inventados de
05J deixam os bindings ativos. A nova paisagem ultrawide deriva do clean plate
anterior e acrescenta árvores densas nas laterais; original e metadados gerados
ficam preservados em review. Cena 16:9, retrato, logo, apoios e esfera mantêm seus
bytes anteriores. A integração é candidata de revisão, sem aprovação artística
atribuída ao usuário; falta confirmar/materializar a prancha revisada de Brasa
inicial. [Escopo e evidências](../docs/live-title-identity.md).


V04-UX-05L: `ui/living-title@2.1.0` reuses unchanged `characters/foli-lifecycle@1.1.0` repose/wake frames through an explicit dependency. Scene, portrait, logo, orb, supports, ultrawide and shader bytes are identical to2.0.0. No new image generation or pixel processing; no revised Brasa initial was inferred from a proposed evolution sheet. Technical production permits the local candidate with `production_ready: false`; human art, Brasa illustration, Lonlon extended-paw art and dedicated Foli stretch remain open. See docs/live-title-polish.md.
