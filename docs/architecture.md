# Architecture and behavior contracts — Umbral 0.3

## Responsibilities

- `content/catalog.tres`: explicitly ordered species manifest, preserving seeded capture order.
- `content/umbrals/<species_id>/`: species/form/power/presentation Resources, original assets, provenance and pure trait implementations.
- `scripts/catalog/`: typed Resource schemas and presentation validation.
- `scripts/content.gd`: authored roots/default facade; `scripts/catalog/game_catalog.gd` is the explicit per-run dependency. `create_catalog()` forks Resource graphs while retaining shared power identities within each species. Rules, projections and runtime views read their run catalog; tests never edit authored globals.
- `scripts/domain/selection_planner.gd`: pure heuristic enumerates subsets up to three, preserving the original tie order without exponential masks.
- `scripts/domain/run_snapshot.gd` / `snapshot_records.gd`: versioned, atomic checkpoint codec and typed validation; `scripts/session/run_replay.gd` applies a whitelist of real rule commands.
- `scripts/domain/models.gd`: typed individuals, cards, reward offers, evaluations and resolution results; detached JSON serialization.
- `scripts/domain/ids.gd`: stable screen, phase, reward and feedback-event IDs.
- `scripts/domain/mechanics.gd`: explicit pure trait/passive effects; `catalog_validation.gd` checks references and supported mechanics.
- `scripts/rules.gd`: deterministic state machine, pure complete round projection, deck recycling, casts and rewards.
- `scripts/main.gd`: composition root and session commands. It mounts views, routes intent and coordinates services.
- `scripts/ui/screens/`: title, battle, settings, rewards/replacement, information and general overlays. Views own nodes, read rules and emit intent.
- `scripts/ui/navigation.gd`: semantic control registry, lifetime cleanup and focus restoration.
- `scripts/ui/combat_feedback.gd`: cancelable feedback, tracked tweens/labels and interruptible waits.
- `scripts/session/statistics.gd`: validated, idempotent completed-run statistics and observable save status.
- `scripts/platform/browser_diagnostics.gd`: opt-in read-only Web protocol and input acknowledgements.
- `scripts/ui/`: screen stack, named input, atomic preferences, theme/buttons, persistent cards/hand, actors, world, health display, bounded effects and audio.

There are no network services, credentials or analytics endpoints. JSON gameplay logs go to stdout. Saves contain completed runs, wins, best applied damage and a separate validated preferences file. No personal data is collected. The Godot project lives at the standalone repository root. The legacy native user-data location is preserved so moving the source does not reset existing saves.

`scripts/storage.gd` stores small JSON records atomically on desktop and synchronously in browser `localStorage` on Web. Web `FileAccess` writes depend on an asynchronous IndexedDB sync; navigating immediately could otherwise restore an older record. Preferences and statistics have separate versioned keys. Existing Godot files remain readable as a fallback for migration, and callers validate loaded fields before applying them. Storage errors leave the current session usable and emit a warning; they must not be described as a successful save.

## Individuals and content

Each individual has `uid`, `species_id`, `form_id`, `passive`. Species/form IDs are stable independently of display names. The species defines the trait implementation; each form defines its strength and full explicit power list. Capture starts at the species' declared initial form with a seeded passive roll. Evolution follows a declared outgoing transition and preserves UID/species/passive. Any number of forms and branches is supported; no ordinal stage or hardcoded maximum exists.

Current base forms contribute two copies of three powers; their evolved forms explicitly contribute upgraded powers and a signature. This is authored data, not a universal formula. Other forms may remove or replace powers. Every card has a unique `instance_id`, current `owner` UID and `power` ID. Even duplicate species are separate individuals; trait limits and Ágil apply per UID.

See [adding-umbrals.md](adding-umbrals.md) for `.tres` structure, branching transitions, authoring commands, readiness gates and presentation contracts. The existing art was moved without byte changes; explicit procedural clips and left mirroring preserve its provenance. No new drawn frame sets are implied.

The deck is rebuilt from the current team between encounters. Released owners leave no cards behind. Used powers move to a discard pile; depleted decks recycle it with the same local RNG. Cards in the current hand are never duplicated during recycling.

## Growth contracts

See [adding-gameplay-content.md](adding-gameplay-content.md) for typed effects, statuses,
phases, enemy actions, reward tables and inventory. `combat_records.gd` holds detached
requests/events/status state. The shared pure resolver is used by power, item and enemy
requests. Feedback consumes applied events; history and stdout preserve attribution.

Power identity is shared at species scope; form variants author full effects and cost.
`content/expedition.tres` orders encounter Resources. Environment Resources own scenery,
lighting and music; rewards are authored tables. `content/items/catalog.tres` contains a
real tonic and an optional relic. Item instances/equipment remain runtime data in
`domain/inventory.gd`; equipment binds to stable UID across evolution.

See [visual-style.md](visual-style.md) for the visual Resource shared by native Theme,
custom components and motion. The presentation catalog loads fonts independently from
the gameplay catalog so pure rules do not load rendering assets.

## Combat contract

Deal 6. Select 1–3 distinct card instances. A simultaneous cast must cost at most 3 energy after individual Ágil discounts. Selection order must not change numerical results. Invalid owner, unknown/locked power, duplicate instance, empty cast or excess budget must fail without consuming rounds, health or randomness.

Preview is pure. `evaluate()` returns typed power effects; `project(cards)` / `preview_round()` also compute applied damage, effective healing, retaliation, remaining health, burn, round budget and phase. `play()` commits that projection, then performs seeded reward/draw operations. HUD and bot reuse the projection. It delegates effect composition to `domain/cast_evaluator.gd` and execution to `domain/effect_resolver.gd`, using explicit form variants, individual passives, species traits and the +6 link for three distinct active UIDs. Circuito Vivo counts other active individuals; Raízes Vivas heals once per protecting individual per round. Ágil discounts the selected powers' total once per individual, never every card.

Resolution order:

1. Deal direct damage plus accumulated/new burn's tick.
2. Decay burn by one, clamped to zero.
3. Apply healing, capped at max health.
4. Spend a round and discard selected powers.
5. If the enemy died, skip retaliation and generate rewards or victory.
6. Otherwise apply announced intention damage minus this cast's shield.
7. Zero health or an exhausted seven-round budget causes defeat.
8. Refill the hand, recycling the discard pile as necessary.

Cast shield expires after retaliation; item-granted shield waits for that cast. Enemy shield protects the next cast. Exchanges consume one of two charges but do not advance the round, burn or enemy intention. Damage statistics count applied damage, excluding overkill.

## Rewards and transitions

`battle → reward → battle → reward → battle → victory`; any battle can end in defeat.

Reward offers are rolled once when the enemy dies. Reopening or cancelling a dialog must not reroll passives. Capturing into a full team requires an explicit replacement UID. Cancel leaves the same reward and team intact. Each eligible outgoing transition is its own offer, storing source/target form and transition IDs. Confirmation revalidates the edge and requirements; optional health cost is spent before reward healing. Evolution changes form and preserves UID/species/passive. Successful reward grants up to 8 health and refreshes encounter budgets.

## Validation boundaries

The title does not start gameplay until Play. A stack owns the active screen and restores focus: menu → codex/options/help; battle → pause → options; battle → inspection/reward/replacement/result. Back pops one layer. Leaving an expedition requires explicit confirmation. Semantic controls have explicit focus neighbors; all input paths share the same rules. The feedback controller owns the busy guard and generation token. Cancel wakes its interruptible timer, kills tracked tweens, clears transient labels/effects and restores transforms. Returning to title, quitting, changing text scale and enabling reduced motion during feedback cancel safely without undoing a committed action.

`rules.state_changed` drives the HUD; only visual interpolation/idle/effects run each frame. Selection keeps card nodes alive. Visual RNG is separate from combat RNG. Reduced motion clears current effects and updates existing cards/actors. Flashes default off. Large text rebuilds views and restores semantic focus. SFX voices (4) and particles (64) are bounded. Graceful shutdown stops audio streams before engine exit.

The numerical rule suite is independent of UI and includes fixed expected values for all traits, passives and evolved signatures. It checks rejected actions, deterministic seeds, replacement, stable rolls and power conservation across 100 complete simulations.

`tools/harness_lib/registry.py` owns the dependency graph for focused checks, browser scenarios, exports and full acceptance. `tools/harness.py` exposes planning, filters, checked cache/resume and isolated parallel tasks; see [harness.md](harness.md). `tools/check.sh` preserves exit codes, rejects Godot script errors, verifies a nonzero executed assertion count, and checks real scene startup. `tools/mutation_smoke.py` runs isolated temporary copies with two deliberate regressions; tests must fail behaviorally without crashes. It never edits the real project.

The full checkpoint API preserves exact RNG state, next UID, inventory, all piles, offers, history and the last projected state separately from later item use. JSON encodes 64-bit RNG values as decimal strings. Restore validates the catalog signature and all records before committing; invalid data leaves the run untouched. This is a developer/test API, not a player-facing continue-run feature.

The browser harness operates real controls in the exported Web game. Its read-only bridge is enabled by `?test=1`; it exposes no mutation methods. Input/Control acknowledgement counters synchronize actual input. `&visual=1` freezes ambient idle motion only. The plan exercises capture/evolution and alternate full-team replacement. It checks deterministic rule state, illegal energy, persistence, focus, modal layers, layout, titles and solid-button text contrast. This validates integration; it does not replace independent expected-value tests.

`tools/iterate.py` runs rules/UI, Web export and the browser matrix, records source hashes, preserves each timestamped attempt and generates a comparison gallery/notes form. See `docs/iteration-harness.md` and `docs/ux-contracts.json`. Automated passes never constitute aesthetic approval or a proof of fun.

Browser rendering uses software WebGL in the cloud. Native Linux startup is checked headlessly. Windows export is not Windows execution. Hardware performance, subjective fun and Steam integration are not established by these tests. CI must not be reported as remotely passed until a real GitHub run exists.

## Conventions

Read [architecture-guidelines.md](architecture-guidelines.md) for the change/verification map, dependency policy and reasons. `tools/architecture_checks.py` enforces ownership and proves nineteen representative architectural regressions are rejected. Use explicit GDScript types at public boundaries. Keep randomness local, seeded and outside preview. Keep copy in Portuguese through native text/tr calls. The 1600×900 reference canvas expands across aspect ratios; controls anchor to edges/centers and flow through containers. Desktop is the target. New content goes in the catalog; new mechanics require behavioral tests; UI changes require the iteration harness and rendered review. Record asset provenance and retain font licenses in distribution bundles.

Avoid unrelated backends, plugin systems and analytics stacks. Read the local Umbral skill for the development workflow.
