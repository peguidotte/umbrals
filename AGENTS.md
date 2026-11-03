# Umbrals

**Umbral: Ecos do Bosque** lives at this repository's root. Use the existing checkout; do not create a worktree unless asked. The local workflow skill is `.agents/skills/umbral/SKILL.md`.

- Engine: Godot 4.6.3, GDScript with explicit types at public boundaries.
- Read `docs/architecture.md` and `docs/architecture-guidelines.md` before changing game behavior.
- Rules/projection belong in `scripts/rules.gd`; catalog Resources/assets in `content/umbrals/<species_id>/` and ordered `content/catalog.tres`; pure species traits in package `mechanics/`, common passives and typed records in `scripts/domain/`; session commands in `scripts/main.gd`; views/navigation/feedback in `scripts/ui/`. Views emit intent and must never hold the coordinator or mutate rules.
- For experience changes, read the mandatory installed skills `.agents/skills/game-ui-ux/SKILL.md` and `.agents/skills/game-feel/SKILL.md`. Use related engine, input, audio and asset skills as needed. The downloaded source/hashes live in `skills-lock.json`.
- Read `docs/art-direction-v0.3.md` and `docs/ux-contracts.json` inside the game. Preserve the visual target unless the user changes it.
- For powers/statuses/items/enemies read `docs/adding-gameplay-content.md`; for shared visual components read `docs/visual-style.md`. Keep definitions immutable, effects pure and feedback based on committed events.
- For species/forms/content changes, read `docs/adding-umbrals.md`. Use stable species/form IDs and declared evolution edges, never numeric stages. Run the package validator and inspect all form/direction/action combinations in the gallery.
- A trait is species-specific. A passive belongs to an individual and persists through evolution. Every power must belong to a current team member.
- Keep seeded randomness reproducible. Never use global random calls for gameplay.
- Read `docs/harness.md` before choosing validation steps. During development run the affected task/case first (`python tools/harness.py check --suite effects --case enemy_shield`); dependencies are automatic. Use `plan --changed` to find affected tasks. Focused success never counts as complete acceptance.
- Runtime rules receive a per-run catalog; fixtures must fork it, never mutate `Content.SPECIES`. Keep action planning in `domain/selection_planner.gd`, outside rules. Use validated `export_state()`/`restore_state()` for checkpoints and whitelisted replay commands; diagnostic `snapshot()` is not a save.
- `tools/harness_lib/registry.py` owns tasks, dependencies and full coverage. Add checks there, with declared inputs; keep outputs/user data isolated. Preserve cache/resume fingerprint verification, process cleanup and full-source freeze. Browser fixture boot stays test-only; the production bridge remains read-only.
- `bash tools/check.sh` runs the headless set. For delivery, run the full graph once after fixes and source freeze, using `verify --full` or the visual iteration below. Do not repeat complete browser runs for unrelated development steps.
- `tools/architecture_checks.py` enforces layers, ownership, stable events, local RNG and typed runtime records; negative cases prove it rejects regressions. Do not bypass it through host helpers, dynamic imports or raised budgets.
- The check runner validates actual test counts and must detect representative mutations; do not weaken it to make changes pass.
- For UI changes, run `python tools/iterate.py --label <iteration> --goal '<observable goal>' --baseline <previous-evidence>`. It runs checks, Web export and real browser input once, preserves logs/captures and generates a review page. Add `--video` when changing motion. Inspect the actual screenshots/video and record concrete review notes before claiming an improvement.
- Keep gameplay RNG separate from visual RNG; attach feedback to events. A screen stack owns input/focus, and the HUD updates from rule signals. Modal overlays must stay above raised cards. Accessibility preferences must apply to current nodes.
- Do not turn pixel differences or test counts into a beauty/fun score. If a gate fails, fix the implementation or justified test synchronization; preserve the failed attempt.
- Do not describe headless tests as visual validation or simulated wins as proof of fun.
- Keep assets original or record their provenance in `assets/README.md` and `assets/asset-manifest.json`. Preserve original generated-media metadata and font licenses.
- Never commit build output, iteration artifacts, credentials, machine-local paths or user saves.
- Do not push, publish to Steam, or create a public release without authorization.
