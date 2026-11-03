# Architectural refactor — validation and rendered review

Goal: preserve the 0.3 game while separating ownership and making architectural regressions detectable.

## Executed evidence

- Before: `artifacts/architecture-before-20261102T114213445859Z` — passed, video and five viewports.
- After: `artifacts/architecture-after-20261102T115952265374Z` — passed, 641 browser checks, five viewports, video and comparisons.
- Rules: 5,892 checks; 100 seeded simulations; two deliberate gameplay mutations detected behaviorally (12 and 3 failing checks respectively).
- Domain/UI/lifecycle: 115 checks, including catalog references, pure projection, save failure, idempotent statistics, cancellation, view replacement and control cleanup.
- Architecture: 33 modules checked; eleven deliberate regressions rejected.
- Web/Windows/Linux bundles exported and packaged. Native Linux started and shut down gracefully without reported errors/leaks. Windows was exported, not executed on Windows.
- The complete primary and replacement browser plans compare equal to the baseline, including hands, rolls, outcomes and reward decisions.

After the browser run, rule assertions were strengthened to compare detached serialized values rather than object identity. `test-results/architecture-final-check.log` records a new complete passing headless check of that test-only change. Production scripts and exported presentation were unchanged after the browser capture.

## Render observations

Inspected menu, battle, capture, evolution/boss, victory and replacement screenshots, plus large-text battle at 1024×768 and 2560×1080. Menu, guide, battle, capture, evolution, boss and replacement captures were also pixel-identical to the baseline; this is preservation evidence, not a beauty score.

- The title's initial focus remains on Start. Its text, portrait placement and five menu choices retain their spacing.
- Combat retains the enemy intention/health at upper right, player health at upper left and the card fan/actions below. Enlarged text stays inside the inspected 4:3 and ultrawide canvases.
- Capture/evolution retain three separate choices, passive explanations and a visible focused action. Replacement retains the current individuals and an explicit keep-team cancel action above the dimmed combat.
- The evolved signature and predicted lethal attack remain visible in the boss capture. The result overlay remains above the cards and shows the same 530 applied damage for seed 42013.
- Sampled the actual recorded video around 76–78 seconds and the settled state thereafter (`feedback-video-sequence.png`, `feedback-video-frames.png` in the after artifact). Selection rises, casting briefly locks its action, impact/burn numbers appear as health settles, and controls return to rest. The sampled sequence shows a single committed cast; dedicated input tests independently check double-cast rejection.
- Cancellation cases intentionally finish presentation immediately when leaving a session, rebuilding text scale or enabling reduced motion; they preserve the already committed rules result. This is the lifecycle improvement, rather than a visual redesign.

Decision: accept the refactor for preserving the inspected experience and passing the stated contracts. No new balancing or fun claim. Sampling is not exhaustive video inspection; software WebGL, real hardware/audio performance, a physical controller and Windows execution remain outside this validation.
