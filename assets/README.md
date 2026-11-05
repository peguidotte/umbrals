# Assets

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
