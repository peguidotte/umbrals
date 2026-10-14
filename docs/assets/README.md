# Modular asset pipeline

Assets have identities independent of their paths, the game version and gameplay definitions. `attacks/fireball-umbral-cast@1.0.0` is one immutable release; its mouth, hand and kick performances reuse effect clips and depend on separately versioned demo characters. The new VFX are prototypes, available for review and integration, and do not silently replace the current game art.

## Layout and ownership

```text
assets/
  domains.json                 # allowed domains
  schemas/module-v1.schema.json
  runtime-lock.json            # exact production bindings used by the game
  catalog.json                 # generated module/version index
  asset-manifest.json          # generated provenance and integrity inventory
  attacks/<slug>/versions/1.0.0/
    manifest.json
    textures/                  # PNG atlases or static illustrations
    data/                      # timing, movement tracks and source metadata
    review/                    # previews and originals, ignored by Godot
  characters/<slug>/versions/1.0.0/...
  umbrals/<slug>/versions/1.0.0/...
```

Domains are `attacks`, `characters`, `umbrals`, `traits`, `passives`, `items`, `audio`, `world`, `fonts` and `ui`. A trait is species-specific; a passive belongs to an individual. Those rules stay in `scripts/content.gd` and `scripts/rules.gd`; asset manifests describe presentation. Empty domains have a README rather than invented game content.

Put shared art in its own module and declare exact `{id, version}` dependencies. An attack owns its effects and performances; a character owns its sprite sheet. An Umbral module can eventually depend on character animation modules without copying their textures. Each file has a role, relative path, SHA-256, byte count and provenance. Per-file provenance can override the module source, including lossless atlas normalization. Generated-media originals, metadata and font licenses remain available.

## Releases and runtime pins

Use canonical `MAJOR.MINOR.PATCH` versions. A patch fixes compatible art or metadata; a minor version adds compatible roles/animations; a major version changes existing roles, pivots, timing contracts or other consumer assumptions. The version describes compatibility, not subjective art quality. Draft, prototype, production and deprecated releases are all immutable once merged into the base branch. Deprecation is represented by a new release and a documented migration; do not rewrite old manifests.

`runtime-lock.json` selects exact production releases and file roles. Adding a version never advances a pin. Prototype modules must be reviewed and copied into a new production release before a game binding can point at them. Keep old releases while any saved content or shipped build may need them. The module schema is also versioned; introduce `module-v2.schema.json` for incompatible schema changes instead of modifying a published v1 schema.

```bash
python -m pip install -r tools/requirements-assets.txt
python tools/assets.py new items/moon-shard --description 'Inventory illustration'
# Add files, declare their roles/provenance, then record their hashes:
python tools/assets.py refresh items/moon-shard 1.0.0 --base-ref origin/main
python tools/assets.py build
python tools/assets.py validate --base-ref origin/main

# Evolve an existing release without changing its files or runtime pin:
python tools/assets.py bump attacks/fireball-umbral-cast --from 1.0.0 --to 1.1.0 --change 'Add a tail-cast performance'
```

`refresh` refuses to alter a release already present in the base branch. It refreshes declared file hashes, sizes and image metadata; animation contracts still require explicit review when replacing a texture. Run `build` after edits; it regenerates the catalog, provenance inventory and `scripts/assets/binding_paths.gd`. Commit those generated files with the source changes. Build output, import caches and iteration captures stay ignored.

## Godot consumption

`scripts/assets/catalog.gd` resolves logical production bindings and exposes `manifest(id, version)`, `file_path(id, version, role)`, `sprite_frames(id, version, animation, low_quality)` and `sprite_layout(...)`. Static textures, audio and fonts continue to use Godot's resource importer. The catalog does not select a latest version or discover assets by filename.

```gdscript
const Assets = preload("res://scripts/assets/catalog.gd")

var portrait: Texture2D = Assets.texture("umbrals/ember")
var clip: SpriteFrames = Assets.sprite_frames("attacks/fireball-comet", "1.0.0", "impact")
var layout: Dictionary = Assets.sprite_layout("attacks/fireball-comet", "1.0.0", "impact")
```

Apply the returned offset and scale when using a centered `AnimatedSprite2D`. Animation manifests specify frame count, FPS, loop, cell grid and pivot. High/low quality shares the same world-space size and pivot. Atlas pages stay at or below 4096 pixels; page switches preserve frame order. Movement, foot tracks and choreography are explicit JSON data, separate from the effect clips. Integration must choose source and target positions and apply those tracks; creating a `SpriteFrames` resource alone does not play a complete attack.

`performances` describes casting variants, including separately pinned actors and launch/release timing. Existing source choreography JSON is retained under `data/` for the full prototype. Demo rigs are illustrative characters, not production Umbrals.

## Validation and migration evidence

`bash tools/check.sh` includes Python catalog tests, asset integrity checks and Godot consumer tests alongside existing gameplay/UI checks. CI additionally compares against the PR base (or previous push commit) and rejects changes to an existing release or schema. Validation covers schema, exact hashes and sizes, ownership, safe paths, atlas grids, transparency, pivots, low-quality parity, dependency cycles, stale generated files and production pins. It does not establish visual quality or performance on every target device.

The original 37 source files are recorded in `migration-map.json`, with original/destination paths and hashes. The pre-migration provenance/audio manifests are archived here unchanged. Original generated forest pixels and PNG metadata are preserved. The four oversized classic-prototype atlas sources remain under their release's `review/`; runtime copies were repacked without resizing or changing frame pixels. `tools/normalize_atlas.py` provides that staging operation.

See `tools/asset_authoring/README.md` for editable VFX sources and `assets/*/README.md` for domain ownership. Before promoting an asset, review its preview, animation endpoints, launch alignment and destination impact in a real scene; record an iteration using the repository's existing harness when changing the game experience.
