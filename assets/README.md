# Assets

Asset modules live at `<domain>/<slug>/versions/<semver>/`. Each release owns a manifest with file roles, provenance, hashes, animation contracts and exact dependencies. Existing game art is migrated without visual changes; new attack effects and demo actors are prototypes.

Read [the architecture and workflow](../docs/assets/README.md) before adding or evolving art. `runtime-lock.json` pins production art; `catalog.json`, `asset-manifest.json` and the Godot binding paths are generated with `python tools/assets.py build`. Validate with `python tools/assets.py validate --base-ref origin/main`.

Domains: attacks, characters, umbrals, traits, passives, items, audio, world, fonts and ui. Character motion and attack effects are separate reusable modules. Empty domains are reserved for future assets.

Original source art remains original to the project. Editable vector/audio sources are in `tools/generate_assets.py` and `tools/generate_audio.py`; VFX sources and references are in `tools/asset_authoring/`. Font licenses are preserved both here and in the font module. Original generated forest PNG metadata is retained. Archived pre-migration inventories and the exact migration map are in `docs/assets/`.

## Battle assets

The original first-stage and evolved battle atlases and grounding maps are in `characters/battle-creatures` and `characters/battle-evolved`; their PNG bytes are preserved. The maps use the module texture paths. The original battle provenance and prompts are retained alongside the first atlas. `world/battle-clearing-depth` is the reviewed wide arena, while `world/battle-clearing` retains the earlier artwork. Water portraits, power icons and the backpack are original project vectors. The original v0.4 inventory, including generation briefs, source hashes and review context, is archived in `docs/assets/original-v0.4-manifest.json`.
