# Asset provenance

## Battle depth revision (V04-ART-06A)

`world/battle_clearing_depth.png` is the current wide battle arena, generated as
an Image Gen edit from the previous arena and our original creature atlas. The
2172×724 PNG is byte-identical to the generated original. Its exact prompt is
in `battle/depth-background-prompt.txt` and `battle/depth-background-panorama-prompt.txt` and the manifest/provenance JSON. The
earlier `battle_clearing.png` is preserved as prior artwork. Eleven `grounding`
profiles in the atlas JSONs describe visible feet/footprint width; layout uses
those values at runtime without editing the character PNGs. In-engine review:
`docs/visual-review-depth-v0.4.md`.

- Base Umbrals: `ember.svg`, `moss.svg`, `volt.svg`.
- Evolved forms: `ignivar.svg`, `verdalio.svg`, `tempestral.svg`.
- Enemies: `spore.svg`, `owl.svg`, `stag.svg`.
- Power illustrations: twelve original SVGs in `powers/`.
- All of these are original vector designs for this project. Editable source: `tools/generate_assets.py`.
- `select.wav`, `play.wav`, `reward.wav`: original synthesized tones from that script, without external samples.
- `hover`, `draw`, `capture`, `evolve`, `fire`, `leaf`, `storm`, `impact`, `ambience` and `boss_pulse` WAVs: original deterministic PCM synthesis from `tools/generate_audio.py`. `audio-manifest.json` records durations and unclipped source peaks. Ambient/boss loops and Music/SFX/UI buses were added in v0.3.
- `body.ttf`, `display.ttf`: DejaVu Sans and DejaVu Serif from the environment's Debian font package. Their license is preserved in `FONT-LICENSE.txt` and distribution bundles.
- `world/clearing.png`: original image generated with the OpenAI Image Gen tool for this project. 1672×941 RGB, 2,303,981 bytes. The exact original PNG was copied without image edits, retaining its metadata. The tool did not expose a model/version; none is inferred. The recorded generation brief, hash and edit history are in `asset-manifest.json`. Aspect-cover and UI readability shading are drawn in Godot.

Every runtime source asset is listed with provenance and SHA-256 in `asset-manifest.json`. Technical QA checks hashes, forest dimensions/alpha and PCM clipping; actual game-scale review is recorded in `docs/visual-review-v0.3.md`. Keep editable source, original generated-media records and the font license in the pipeline. No artwork or samples from commercial games are included.

## Primeira batalha coletiva

- `battle/creatures.png`: sete sprites originais em pixel art; quatro aliados e três adversários, com alfa transparente.
- `battle/evolved.png`: quatro formas evoluídas coerentes, em edição com margens transparentes maiores. O candidato anterior ficou preservado em `artifacts/battle-runtime-art-20261018/`; não foi distribuído.
- `battle/atlas.json` e `battle/evolved-atlas.json`: regiões aplicadas por `AtlasTexture`, sem recortar ou regravar PNGs.
- `world/battle_clearing.png`: arena original do pântano lunar, sem HUD ou criaturas pintadas no fundo.
- `battle/provenance.json`: briefs/prompts disponíveis, origens e hashes dos três PNGs, revisão e limitações. O prompt exato da edição final de espaçamento não estava disponível após o encerramento do trabalho delegado; o brief está identificado como tal.
- `dew.svg`, `mareveu.svg` e os três ícones de água em `powers/`: vetores originais provisórios para fallback e cartas.
- `icons/backpack.svg`: ícone original da mochila, desenhado para o HUD.

A primeira entrega usa poses estáticas com feedback procedural. A aprovação da composição não equivale a aprovar todo o catálogo ou animações finais.
