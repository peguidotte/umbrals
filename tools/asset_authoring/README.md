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

## Fifteen attack choreography studies

`python tools/asset_authoring/build_attack_studies.py` now builds the revision 2 standalone offline
`builds/attack-studies-v2/galeria.html`, fifteen 30 FPS MP4/GIF previews, a combined
comparison, six-pose review strips and a sequential video. Requires Pillow, Playwright, system Chromium
at `/usr/bin/chromium`, and ffmpeg. The HTML source is `attack_studies.html`;
`attack_actor_rig.js` owns local joint skinning and posed emission sockets;
`attack_studies_v2.js` owns the fifteen performances and distinct effect materials.
The builder embeds the current original battle atlases and arena without
modifying their source files. Review controls include independent pause/seek,
global speed, enlarged view, base/evolved actors, a joint/socket overlay and reduced motion.

These are procedural VFX and continuous-mesh choreography studies, without audio
or redrawn frame-by-frame poses. Local head, tail, limbs and crest/reservoir motions
share their deformation with the named emission socket; preparation, release,
counterweight and recovery are authored per performance. They do not modify gameplay, release
existing modules again, or advance production pins. `review.json` records
source hashes, browser checks and limits. Integration and authored poses need
their own subsequent asset/runtime slice. The first version is preserved in
`builds/attack-studies-v1/`; the initial v2 take in `builds/attack-studies-v2-pass1/`.

After rendering, `python tools/asset_authoring/review_attack_studies.py` validates
fifteen VFX packets, decodes every video, creates the tail-cast before/after clip
and packages the offline gallery, GIFs and videos. The first-version `02.mp4`
must exist for that comparison. Canvas design caps are not Godot GPU profiling.

## Revision 3: creature states and calibrated emission

```bash
python tools/asset_authoring/build_attack_studies.py --revision 3
python tools/asset_authoring/review_attack_studies.py --revision 3
```

The offline gallery in `builds/attack-studies-v3/galeria.html` adds six states
(idle, preparation, cast, hurt, guard, celebration) for eight explicitly named
forms. `umbral_anatomy.js` owns form-specific source points and local motion;
`attack_studies_v3.js` owns the state gallery, presentation contact hold and
layered impacts. The atlas grounding metadata anchors each form to the floor.
Emission points for base and evolved forms are authored separately and follow
the same mesh transformation as the visible actor. Impact numbers are study
illustrations, not a second gameplay resolver. Audio and runtime integration
remain outside this review artifact.

Outputs include the fifteen attack clips, a 48-second attack reel and a
19.2-second eight-form/six-state reel (`vida-umbrals.mp4`). The builder checks
distinct state pose sequences and all thirty posed base/evolved emission points.
The reviewer decodes the exported videos, validates VFX packets and creates a
comparison with revision 2 plus a ZIP. Frames persist under `frame-cache/` with
an input fingerprint, so a compatible interrupted render can resume; cached
frames and intermediate attempts stay in ignored `builds/`.

These remain continuous-mesh studies using the original sprites, without
new hand-drawn frame sequences. Performance budgets are authoring caps, not
measured Godot/hardware performance. `--html-only` rebuilds the standalone gallery
without exporting review media.

`REFERENCIAS.md` records visual study references. References informed timing and shape language; third-party game art was not copied into the assets. The installed `.agents/skills/game-vfx/SKILL.md` provides the VFX review workflow.

## Revision 4: illustrated effect assets

`attack_studies_v4.js` replaces the fifteen studies' main effect shapes with the
original Image Gen atlas `attacks/woodland-elements@1.0.0`. Sixteen distinct
silhouettes cover fire, bark/thorns, water/foam and gold/blue electricity.
Curved textured ribbons share mesh vertices; directional fragments stay subordinate
to the contact shape. The original PNG and embedded generation metadata are preserved.
Character motion keeps the existing sprites, limits extreme local rotations and adds
wing, antenna, bough and fin follow-through. This is still mesh animation, not redrawn poses.

```bash
python tools/asset_authoring/build_attack_studies.py --revision 4
python tools/asset_authoring/export_element_clips.py
python tools/assets.py refresh attacks/woodland-elements 1.0.0 --base-ref origin/main
python tools/assets.py build
python tools/assets.py validate --base-ref origin/main
python tools/asset_authoring/review_attack_studies.py --revision 4
```

The clip exporter bakes sixteen transparent 12-frame sheets: 192×192 cells,
4×3 layout, 24 FPS and a fixed 96×96 pivot. Impacts play once; other clips loop.
It refuses to overwrite a version already on origin/main. Source atlas and clips
are registered as a prototype module; runtime pins are unchanged. Review media
and the offline gallery are in `builds/attack-studies-v4/`.

## Revision 5: personality, weight and sound

```bash
python tools/asset_authoring/build_attack_studies.py --revision 5
python tools/asset_authoring/review_attack_studies.py --revision 5
```

`attack_choreography.json` owns the fifteen event clocks: preparation, release,
contact, a 50–100 ms presentation hold, consequence and recovery. Visuals and
sound share those seconds. `attack_personalities.js` owns eight explicit body
profiles, fifteen gestures and species/material responses. Targets face the
caster; the gallery can swap the receiver to compare the same hit against
Ignivar, Verdálio, Marevéu and Tempestral, with explicit initial-form mappings.
Wood variants keep two semantic victims; no game targeting or resistance rule changes.

`attack_studies_v5.js` composes constrained camera impulse, directional material
debris, traces on the floor, caster recoil and victim recovery. Cut, whip, thorn
volley, water pressure, wave, electric pulse/bind and body slams have different
responses. Reduced motion removes motion, camera displacement and particles;
camera motion and optional local impact light have separate controls.

`attack_study_audio.py` synthesizes fifteen original stereo WAVs, with quiet
charge/strain, release, contact/body thump and material tail. Sound uses seeded
local synthesis with bounded peaks, never external samples or gameplay RNG.
`attack_study_sound.js` previews one selected performance from an explicit click,
following the audio clock and stopping when the modal closes or playback changes.
Offline HTML embeds images and audio. Individual attack MP4s and the 48-second
reel include stereo AAC; the short highlights reel lasts 13.5 seconds.

Exports remain review prototypes, with existing character pixels animated by
mesh. They are not integrated Godot behavior or new hand-drawn pose sequences.
Digital decode/peak checks do not claim a headphone, speaker or hardware test.

## Approved performances in the game — V04-ART-08A

The user approved revision 5 and requested integration into current main.
`export_battle_performances.py` bakes the approved normalized pose tracks,
anatomy, sockets and clocks into separately versioned production modules. It
retains the prototype module and refuses to overwrite released versions.

```bash
python tools/asset_authoring/export_battle_performances.py
python tools/assets.py build
python tools/assets.py validate --base-ref origin/main
python tools/harness.py check --suite battle-motion
```

Native rendering lives in `scripts/ui/creature_rig.gd`, `battle_motion.gd`,
`battle_vfx.gd` and `battle_choreography.gd`. Presentation consumes existing
resolution events and snapshots without changing mechanics or gameplay RNG.
The shared clocks schedule original audio through the existing bounded pool.

To record actual game input/output, first obtain the disposable `web-fixtures`
export, then run:

```bash
python tools/capture_battle_performances.py --build-dir <fixture-build> --output artifacts/<unique-review>
```

The eight finite `motion_*` fixtures use validated expedition snapshots, owned
cards and three durable test receivers. Their HP is review endurance, not a
production balance change. The recorder clicks cards/targets and commits real
turns; it captures the game canvas and actual WebAudio output together. It
rejects silent recordings and never adds a replacement soundtrack. Test entry
and fixture data are excluded from the production PCK. Full acceptance still
uses `tools/iterate.py --video`; the capture tool is additional visual evidence.
