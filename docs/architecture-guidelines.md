# Guidelines for the next development session

Read this file and architecture.md before changing behavior. `tools/architecture_checks.py`
is part of `check.sh` and every full iteration. It rejects known architectural regressions;
it does not prove correctness, visual quality, fun or the absence of every possible coupling.

## Ownership and dependency direction

| Change | Owner | Verification |
|---|---|---|
| New species, form, power, art, evolution and sound association | `content/umbrals/<species_id>/` Resources/assets | `adding-umbrals.md`, package/graph contracts, gallery, numerical values |
| New species trait / common passive | Package `mechanics/` pure trait / `domain/mechanics.gd` | Typed trait contract and independent numerical examples |
| Individuals, cards, offers and results | `domain/models.gd` | Typed API; serialization must not alias live records |
| Energy and phase transitions / effects and status timing | `rules.gd` / `domain/cast_evaluator.gd`, `effect_resolver.gd` | Pure projection + numerical tests; RNG/ownership/conservation |
| Item metadata / quantities, use and UID equipment | `catalog/item_definition.gd` / `domain/inventory.gd` | Effective-use, phase, evolution/replacement and RNG contracts |
| Enemies, actions, rewards and environments | `content/{enemies,encounters,rewards,environments}/`, `expedition.tres` | Pure content contracts, assets and actual PCK comparison |
| Shared style and custom drawing | `content/styles/`, `ui/style.gd` and component owners | Style gallery plus browser five-format matrix |
| Typed effect/event/status records | `domain/combat_records.gd` | Source/target, requested/applied/blocked values and detached history |
| Title, battle, settings, rewards or information layout | Corresponding `ui/screens/*` view | Real input, focus, browser matrix and rendered review |
| Screen lifetime, game commands and service wiring | `main.gd` | Session lifecycle tests and browser integration |
| Focus, control registration/unregistration | `ui/navigation.gd` | Focus restoration and stale-control regressions |
| Animation, anticipation, impact and cancellation | `ui/combat_feedback.gd` | Cancellation tests and video review |
| Completed-run statistics | `session/statistics.gd` | Validation, idempotence, failure and reload tests |
| Preferences | `ui/preferences.gd` | Validation, save failure, current-node accessibility and reload |
| Desktop/Web persistence mechanism | `storage.gd` | Atomic writes, migration, synchronous Web reload |
| Per-run catalog / isolated content overrides | `catalog/game_catalog.gd` | Fork isolation, retained shared identities and catalog fingerprint |
| Selection heuristic | `domain/selection_planner.gd` | Bounded combinations, old tie order and pure projection |
| Complete checkpoints / commands | `domain/run_snapshot.gd`, `snapshot_records.gd` / `session/run_replay.gd` | Atomic rejection, JSON roundtrip, exact RNG and next-action equivalence |
| Task graph / scheduling / scenario input | `tools/harness_lib/registry.py`, runner/executor / `tools/browser/` | Harness self-tests, independent real-input scenarios and complete coverage gate |
| Read-only browser protocol | `platform/browser_diagnostics.gd` | Browser input/acknowledgement tests; no mutation bridge |

The guard assigns every production script to a layer and rejects forbidden imports,
missing dependencies and cycles. The composition root may depend on services and views;
rules/domain/catalog schemas and package traits must not depend on UI, filesystem, input or Web APIs. The catalog facade resolves an explicitly authored Resource graph once; traits cannot load or depend on that catalog. Authored `.tres` and trait dependencies are scanned by the gate. Do not use
global class names, dynamic paths or service locators to bypass these boundaries.

## Rules that prevent the original concentration from returning

- A view owns its nodes and emits intent through `action_requested`. It never stores
  `app`, `host` or `coordinator`, looks up its parent to execute a command, or mutates rules.
  The settings view may update the explicit preferences service.
- Keep widget construction, tweens, direct storage and JavaScript out of `main.gd`.
  Adding a new feature should normally change its owner and add one orchestration hook.
- Do not duplicate combat consequences in the HUD, bot or feedback. Use `preview_round()`
  or `project(cards)`. Only `play()` commits the projection and consumes RNG for rewards/draws.
- Use typed runtime records and typed collections. Dictionaries are appropriate for
  catalog definitions, small validated settings and JSON boundaries; they are not a
  substitute for an individual, card, reward or combat result.
- Use stable IDs for phases, screens, reward kinds and events. Never branch on translated
  text. `TRIPLE_LINK` selects feedback; its displayed label can change independently.
- Gameplay uses the seeded rules RNG. Visual randomness stays in presentation. Preserve
  RNG call order during refactors; changing it intentionally requires recording replay changes.
- Cancellation must wake pending waits, invalidate old callbacks, stop tracked tweens,
  remove transient labels and restore transforms. It must not undo a committed action.
  Replacing a view, returning to title and quitting must all cancel safely.
- Register semantic control IDs through navigation and unregister on tree exit. Preserve
  the browser protocol and focus behavior when extracting screens.
- A successful in-memory preference/result update is not proof of a successful write.
  Services expose `last_save_ok`; warning/failure tests must remain.

## Executable guard and its limits

`python tools/architecture_checks.py` checks dependency direction, cycles, pure-domain APIs,
view command/state mutations, coordinator ownership, stable events, local RNG and typed
runtime collections. It also injects nineteen in-memory regressions and requires each to be
rejected by its intended rule. It never edits the project to run those negative cases.

The module budget is 400 nonblank/noncomment lines for the coordinator and 350 elsewhere.
This is an early warning, not a quality score: a short module can still have bad ownership.
Extract a coherent responsibility instead of hiding code in a helper that receives `host`.
If a justified design needs a policy change, document why here and update its negative
case with the implementation. Never raise limits merely to make a failing change pass.
The guard is lexical: aliases, dynamic dispatch and all possible arithmetic duplication
are not fully analyzed. Godot types, behavioral tests and review remain required.

## Small, reviewable workflow

1. Identify the owner and observable behavior before editing; preserve a baseline for UI work.
2. Change contracts first, then their consumers. Keep literal numerical expected values.
   Follow `docs/adding-umbrals.md` for stable form IDs and evolution graphs; never restore numeric stages.
3. Read [harness.md](harness.md); use `plan --changed` and focused suite/case/scenario checks while editing. The registry owns dependencies and coverage; never duplicate its suite list in wrappers. `check.sh` remains the complete headless set.
4. Once fixes are complete, freeze sources and run `verify --full` or, for UI/feedback, `iterate.py --baseline <previous-evidence> --video`.
   It includes all checks, export, real browser input and five viewport formats. Inspect
   screenshots/video and record specific observations. Preserve failed attempts.
5. Update architecture.md when ownership/contracts change. Keep AGENTS.md as a short index;
   put durable decisions and the change/verification map here, not in conversational notes.

CI has a fast headless job and a dependent full browser/build job. The second job deliberately
runs its own checks in a fresh runner to bind its source-hashed evidence to that execution;
the fast result never waives any full gate. No push, release or Steam publication is implicit.

## New-content guardrails

- Follow [adding-gameplay-content.md](adding-gameplay-content.md) before adding a power,
  status, item, enemy or encounter. Definitions are immutable; runtime state is separate.
- Form power resources reference one shared species identity and compose typed effects.
  Do not restore fixed exported damage/heal/burn fields or copy metadata per form.
- Preview and execution use the same pure effect resolver. Conditions read the initial
  state; named phases and canonical source order make simultaneous casts reproducible.
- Relics use explicit additive phases. Do not introduce an arbitrary global event bus.
- Feedback/logging/history consume committed events. Never call power evaluation from
  feedback. Preserve cancellation and reduced motion when adding event presentation.
- Inventory screens emit intent, including use/equip. They do not mutate the inventory
  service merely because it is nested below `game`.
- Semantic UI colors belong in the visual Resource; native Theme and `_draw` share it.
  The lexical guard rejects literal hex palettes in UI, direct inventory mutation,
  rule reconstruction in feedback and fixed exported power variants. Nineteen negative
  cases prove these policies fail when violated. Floating-point colors, aliases and
  arbitrary runtime dispatch still require human review.
- `growth_contracts_test.gd` and `growth_ui_test.gd` are required CI suites. Do not remove
  them when refactoring their owners. Browser checks independently use/equip actual
  items and inspect normal/large inventory at five viewports.

## Harness and replay guardrails

- Inject a private catalog into a run and its consumers. Never append fixtures to the
  authored facade. Definitions are immutable during normal gameplay.
- Planning consumes the public pure projection. Keep its heuristic outside the state
  machine and enumerate at most three cards; do not restore a `2^hand` search.
- The diagnostic snapshot and complete versioned checkpoint have different contracts.
  Do not rebuild RNG by guessing past calls or deserialize arbitrary properties. Restore
  only validated typed records and replay only explicit production commands.
- Independent browser scenarios share lifecycle/input primitives, not one long route.
  Boot fixtures exist only in a disposable test export; the release PCK must exclude them.
  Inspect the actual PCK from an empty working directory so Godot cannot fall back to
  excluded source files on disk.
- Cache/resume requires matching declared source/policy/tool inputs and output hashes.
  A focused run may verify only its inputs; full acceptance requires unchanged whole
  sources and fresh behavioral tests. Skipped/interrupted tasks are never passes.
- Preserve project/browser locks, bounded process groups, isolated user data and failed
  evidence. Use measured process and lock-wait times to optimize; do not weaken checks.
