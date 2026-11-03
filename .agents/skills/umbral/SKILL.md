---
name: umbral
description: Build and review Umbral gameplay and experience with repeatable rules, browser input and visual iteration evidence.
---

Use the existing Umbrals checkout; the Godot project is at its root. Do not create a worktree unless requested. Read `AGENTS.md`, the game README, `docs/architecture.md` and `docs/architecture-guidelines.md`.

1. State the intended behavior and observable outcome. For UI/feel work, read the game-local `.agents/skills/game-ui-ux/SKILL.md` and `.agents/skills/game-feel/SKILL.md`, then `docs/art-direction-v0.3.md` and `docs/ux-contracts.json`. Use the installed Godot, input, audio, card-game and asset skills when relevant.
2. Keep deterministic mechanics in `scripts/rules.gd`, ordered catalog and species/form Resources/assets in `content/`, a typed facade in `scripts/content.gd`, pure species traits in each package, typed records/common passives in `scripts/domain/`, session commands in `scripts/main.gd`, presentation in `scripts/ui/`. Views own nodes and emit intent without a coordinator reference. Navigation owns control lifetime/focus through the stack; HUD uses rule signals. Visual effects use separate RNG and bounded pools.
3. For content authoring read `docs/adding-umbrals.md`; create packages with `tools/umbrals.py`, use stable form IDs/explicit transitions and validate all directional clips/assets. Preserve individual UID/passive across evolution. Capture creates another individual; replacement must require an explicit choice. Build decks from current owners and unlocked powers.
4. Preview must be pure: no randomness, rerolls or state mutations. Reject invalid/over-budget actions without spending a round.
5. Read `docs/harness.md`. Start with `python tools/harness.py plan --changed` and the affected task/case/scenario. Dependencies are automatic; `--jobs` coordinates isolated headless tasks. `bash tools/check.sh` runs all headless gates. Focused runs never waive full acceptance. Register tasks only in `harness_lib/registry.py`; declare inputs, preserve cache/resume checks, durable interrupted/failed statuses and per-task user data. Fixtures use a private catalog and validated checkpoint/replay, never global catalog edits or a mutation bridge.
6. After fixes, freeze sources and run the full graph once. For UI/input changes, run `python tools/iterate.py --label <name> --goal '<observable goal>' --baseline <previous-evidence>`, adding `--video` for motion changes. This includes all headless gates and eight browser scenarios; do not run duplicate complete checks without a reason. Nonvisual delivery can use `python tools/harness.py verify --full`. Inspect menu, battle, capture, evolution, boss, replacement, large text and the resolution matrix. Open the generated review page and record specific observations and tradeoffs. A passing run is not visual approval; pixel difference is not a quality score. Preserve failed attempts.
7. To distribute, export the required targets and run `python tools/package.py`. Record asset provenance in the asset manifest/README. Validate the native Linux bundle with its graceful `--headless -- --smoke-exit` path, not an abrupt timed exit with audio running.
8. Report exact outcomes. Separate simulations, browser input, desktop export, real platform execution and subjective playtesting.

Keep generated evidence in ignored `test-results/` and immutable timestamped `artifacts/`; builds in ignored `builds/`. Read `docs/iteration-harness.md` for setup and review. Do not push or publish without user authorization.

For typed effects/statuses, inventory, enemy actions and authored encounters read
`docs/adding-gameplay-content.md`. For Theme/custom drawing use `docs/visual-style.md`.
Keep the new content/UI suites and exported-resource comparisons in the mandatory gates.
