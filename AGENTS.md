# Umbrals

**Umbral: Ecos do Bosque** lives at this repository's root. Use the existing checkout; do not create a worktree unless asked. The local workflow skill is `.agents/skills/umbral/SKILL.md`.

- Engine: Godot 4.6.3, GDScript with explicit types at public boundaries.
- Read `docs/architecture.md` before changing game behavior.
- Rules belong in `scripts/rules.gd`; species, traits, passives and powers in `scripts/content.gd`; session flow in `scripts/main.gd`; reusable presentation in `scripts/ui/`.
- For experience changes, read the mandatory installed skills `.agents/skills/game-ui-ux/SKILL.md` and `.agents/skills/game-feel/SKILL.md`. Use related engine, input, audio and asset skills as needed. The downloaded source/hashes live in `skills-lock.json`.
- Read `docs/art-direction-v0.3.md` and `docs/ux-contracts.json` inside the game. Preserve the visual target unless the user changes it.
- A trait is species-specific. A passive belongs to an individual and persists through evolution. Every power must belong to a current team member.
- Keep seeded randomness reproducible. Never use global random calls for gameplay.
- Run `bash tools/check.sh` from the repository root after gameplay changes.
- The check runner validates actual test counts and must detect representative mutations; do not weaken it to make changes pass.
- For UI changes, run `python tools/iterate.py --label <iteration> --goal '<observable goal>' --baseline <previous-evidence>`. It runs checks, Web export and real browser input once, preserves logs/captures and generates a review page. Add `--video` when changing motion. Inspect the actual screenshots/video and record concrete review notes before claiming an improvement.
- Keep gameplay RNG separate from visual RNG; attach feedback to events. A screen stack owns input/focus, and the HUD updates from rule signals. Modal overlays must stay above raised cards. Accessibility preferences must apply to current nodes.
- Do not turn pixel differences or test counts into a beauty/fun score. If a gate fails, fix the implementation or justified test synchronization; preserve the failed attempt.
- Do not describe headless tests as visual validation or simulated wins as proof of fun.
- Keep assets original or record their provenance in `assets/README.md` and `assets/asset-manifest.json`. Preserve original generated-media metadata and font licenses.
- Asset architecture and authoring workflow: `docs/assets/README.md`. Each module has an immutable `assets/<domain>/<slug>/versions/<semver>/manifest.json`; create a new version instead of editing a version already in the base branch. Keep actors separate from attack effects and pin dependencies explicitly. Game rules and content remain in their existing scripts.
- Update `assets/runtime-lock.json` deliberately; never resolve an asset through an implicit latest version. Run `python tools/assets.py build` after catalog changes and `python tools/assets.py validate --base-ref origin/main` before publishing. Generated indexes and Godot bindings are committed.
- Never commit build output, iteration artifacts, credentials, machine-local paths or user saves.
- Do not push, publish to Steam, or create a public release without authorization.
