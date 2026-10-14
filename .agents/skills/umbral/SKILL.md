---
name: umbral
description: Build and review Umbral gameplay and experience with repeatable rules, browser input and visual iteration evidence.
---

Use the existing Umbrals checkout; the Godot project is at its root. Do not create a worktree unless requested. Read `AGENTS.md`, the game README and `docs/architecture.md`.

1. State the intended behavior and observable outcome. For UI/feel work, read the game-local `.agents/skills/game-ui-ux/SKILL.md` and `.agents/skills/game-feel/SKILL.md`, then `docs/art-direction-v0.3.md` and `docs/ux-contracts.json`. Use the installed Godot, input, audio, card-game and asset skills when relevant.
2. Keep deterministic mechanics in `scripts/rules.gd`, catalog in `scripts/content.gd`, session flow in `scripts/main.gd`, presentation in `scripts/ui/`. Screens own focus/input through the stack; HUD uses rule signals. Visual effects use separate RNG and bounded pools.
3. Preserve individual UID/passive across evolution. Capture creates another individual; replacement must require an explicit choice. Build decks from current owners and unlocked powers.
4. Preview must be pure: no randomness, rerolls or state mutations. Reject invalid/over-budget actions without spending a round.
5. Run `bash tools/check.sh` from the repository root. This includes numerical trait/passive examples, seeded simulations, mutation checks and actual scene startup.
6. For UI/input changes, run `python tools/iterate.py --label <name> --goal '<observable goal>' --baseline <previous-evidence>`, adding `--video` for motion changes. This already includes step 5, so do not run duplicate checks without a reason. Inspect menu, battle, capture, evolution, boss, replacement, large text and the resolution matrix. Open the generated review page and record specific observations and tradeoffs. A passing run is not visual approval; pixel difference is not a quality score. Preserve failed attempts.
7. To distribute, export the required targets and run `python tools/package.py`. Record asset provenance in the asset manifest/README. Validate the native Linux bundle with its graceful `--headless -- --smoke-exit` path, not an abrupt timed exit with audio running.
8. Report exact outcomes. Separate simulations, browser input, desktop export, real platform execution and subjective playtesting.

Keep generated evidence in ignored `test-results/` and immutable timestamped `artifacts/`; builds in ignored `builds/`. Read `docs/iteration-harness.md` for setup and review. Do not push or publish without user authorization.
