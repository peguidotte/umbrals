# Architectural refactoring tasks

Goal: preserve the 0.3 game while making future changes local and verifiable.

1. [x] Capture a source-hashed browser/video baseline.
2. [x] Introduce typed runtime records and a pure complete round projection; retain independent numerical tests.
3. [x] Validate catalog references, centralize stable IDs and isolate trait/passive mechanics.
4. [x] Extract title/battle/overlay views, navigation, statistics, Web diagnostics and cancelable feedback from the coordinator.
5. [x] Add architecture guidelines, executable dependency/ownership checks and negative checks proving the guard rejects regressions; update mutation isolation and split CI stages.
6. [x] Run full checks, browser/video/resolution comparison, inspect renders and record results.

Each task must preserve RNG consumption, deck ownership, saves, semantic control IDs, focus and timing. No architectural gate replaces behavioral or rendered review. See architecture.md and architecture-guidelines.md for ownership and acceptance rules.

## Baseline and intermediate verification

- Baseline: `artifacts/architecture-before-20261102T114213445859Z`, all gates passed, video and five viewports captured.
- The pre-refactor and refactored browser plans compare equal, including capture, evolution, replacement, hands and numerical outcomes.
- Original rule expectations retained: 5,892 checks; current domain/UI/lifecycle suites: 115 checks.
- Failed intermediate attempts remain in ignored `test-results/refactor-*` logs. The lifecycle regression exposed pending waits at shutdown; feedback now uses an interruptible timer that cancellation wakes immediately.

## Completion

All six tasks completed. The coordinator is now 350 lines (previously 903), with title,
battle, modal/settings/reward/information views, navigation, feedback, statistics and Web
diagnostics owning their responsibilities. See visual-review-architecture.md for the exact
evidence and limits. Final checks passed after strengthening value-based immutability tests.
CI YAML and its local summary were validated; no remote CI execution is claimed.
