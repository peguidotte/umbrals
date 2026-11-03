# Asset provenance

- Umbral portraits: original SVGs now under `content/umbrals/<species_id>/forms/<form_id>/portrait.svg`; base and evolved forms share the species package.
- Enemies: `spore.svg`, `owl.svg`, `stag.svg`.
- Power illustrations: twelve original SVGs now under each species package's `powers/` folder.
- All of these are original vector designs for this project. Editable source: `tools/generate_assets.py`.
- `select.wav`, `play.wav`, `reward.wav`: original synthesized tones from that script, without external samples.
- `hover`, `draw`, `capture`, `evolve`, `fire`, `leaf`, `storm`, `impact`, `ambience` and `boss_pulse` WAVs: original deterministic PCM synthesis from `tools/generate_audio.py`. `audio-manifest.json` records durations and unclipped source peaks. Ambient/boss loops and Music/SFX/UI buses were added in v0.3.
- `body.ttf`, `display.ttf`: DejaVu Sans and DejaVu Serif from the environment's Debian font package. Their license is preserved in `FONT-LICENSE.txt` and distribution bundles.
- `world/clearing.png`: original image generated with the OpenAI Image Gen tool for this project. 1672×941 RGB, 2,303,981 bytes. The exact original PNG was copied without image edits, retaining its metadata. The tool did not expose a model/version; none is inferred. The recorded generation brief, hash and edit history are in `asset-manifest.json`. Aspect-cover and UI readability shading are drawn in Godot.

Original portrait/icon bytes and generation records were preserved during the package migration. Per-species `provenance.json` mirrors their entries in the global manifest. Directional mirroring and procedural animation are declared in presentation Resources.

Every runtime source asset is listed with provenance and SHA-256 in `asset-manifest.json`. Technical QA checks hashes, forest dimensions/alpha and PCM clipping; actual game-scale review is recorded in `docs/visual-review-v0.3.md`. Keep editable source, original generated-media records and the font license in the pipeline. No artwork or samples from commercial games are included.
