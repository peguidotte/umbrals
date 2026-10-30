# Editable VFX sources

These deterministic procedural renderers generated the migrated fireball variants, demo rigs and Carpado do Eclipse. They write to ignored staging under `builds/asset-work/vfx`, never directly into a released asset module. Set `UMBRAL_ASSET_OUTPUT` to another staging directory if needed. Authoring dependencies are Pillow, numpy and aggdraw; video preview encoding uses ffmpeg.

```bash
python -m pip install -r tools/requirements-assets.txt numpy aggdraw
python tools/asset_authoring/render.py
python tools/asset_authoring/render_variants.py
mkdir -p builds/asset-work/vfx/v4-umbral builds/asset-work/vfx/mortal-carpado
cp tools/asset_authoring/fireball-vfx-spec.json builds/asset-work/vfx/v4-umbral/vfx-spec.json
cp tools/asset_authoring/carpado-vfx-spec.json builds/asset-work/vfx/mortal-carpado/vfx-spec.json
python tools/asset_authoring/render_umbral.py
python tools/asset_authoring/render_carpado.py
```

The source output retains the original prototype layout. To publish it, use `tools/assets.py new` or `bump`, split actors from effects, normalize oversized atlases with `tools/normalize_atlas.py` and review all manifest contracts. Copy selected sources into the new version, declare their roles and provenance, then refresh, build and validate. Rendering never changes a runtime pin. The preserved source metadata can contain paths relative to the original staging layout; runtime consumers use the new module manifests.

`REFERENCIAS.md` records visual study references. References informed timing and shape language; third-party game art was not copied into the assets. The installed `.agents/skills/game-vfx/SKILL.md` provides the VFX review workflow.
