# Architecture and behavior contracts — Umbral 0.3

## Responsibilities

- `scripts/content.gd`: species, stage names/art, unique traits, useful passive pools, power definitions, signature unlocks and enemy intention patterns.
- `scripts/rules.gd`: deterministic state machine, individuals, owned power instances, deck recycling, simultaneous casts, burn, counterattacks and rewards.
- `scripts/main.gd`: session coordinator, screen construction, feedback events, local statistics and opt-in read-only browser state.
- `scripts/ui/`: screen stack, named input, atomic preferences, theme/buttons, persistent cards/hand, actors, world, health display, bounded effects and audio.
- `scripts/assets/`: exact production resource bindings and version-explicit animation loading. Assets are independently versioned modules; gameplay content stores logical art IDs. See `docs/assets/README.md` for ownership, immutable releases, authoring and CI validation.

There are no network services, credentials or analytics endpoints. JSON gameplay logs go to stdout. Saves contain completed runs, wins, best applied damage and a separate validated preferences file. No personal data is collected. The Godot project lives at the standalone repository root. The legacy native user-data location is preserved so moving the source does not reset existing saves.

## Individuals and content

Each individual has `uid`, `species`, `passive`, `stage`. A species trait is fixed; its strength changes at stage 2. A passive belongs to that individual. Capture creates a new UID with a seeded passive roll; evolution preserves UID and passive. Passive pools exclude meaningless rolls: Vital is offered to Musgo, whose powers can heal.

Stage 1 contributes two copies of three powers. Stage 2 upgrades those powers and contributes two copies of a signature. Every card has a unique `instance_id`, current `owner` UID and `power` ID. Even duplicate species are separate individuals; trait limits and Ágil apply per UID.

The deck is rebuilt from the current team between encounters. Released owners leave no cards behind. Used powers move to a discard pile; depleted decks recycle it with the same local RNG. Cards in the current hand are never duplicated during recycling.

## Combat contract

Deal 6. Select 1–3 distinct card instances. A simultaneous cast must cost at most 3 energy after individual Ágil discounts. Selection order must not change numerical results. Invalid owner, unknown/locked power, duplicate instance, empty cast or excess budget must fail without consuming rounds, health or randomness.

Preview is pure. It calculates base power effects, evolution upgrades, individual passives, species traits and the +6 link for three distinct active UIDs. Circuito Vivo counts other active individuals; Raízes Vivas heals once per protecting individual per round. Ágil discounts the selected powers' total once per individual, never every card.

Resolution order:

1. Deal direct damage plus accumulated/new burn's tick.
2. Decay burn by one, clamped to zero.
3. Apply healing, capped at max health.
4. Spend a round and discard selected powers.
5. If the enemy died, skip retaliation and generate rewards or victory.
6. Otherwise apply announced intention damage minus this cast's shield.
7. Zero health or an exhausted seven-round budget causes defeat.
8. Refill the hand, recycling the discard pile as necessary.

Shield does not carry over. Exchanges consume one of two charges but do not advance the round, burn or enemy intention. Damage statistics count applied damage, excluding overkill.

## Rewards and transitions

`battle → reward → battle → reward → battle → victory`; any battle can end in defeat.

Reward offers are rolled once when the enemy dies. Reopening or cancelling a dialog must not reroll passives. Capturing into a full team requires an explicit replacement UID. Cancel leaves the same reward and team intact. Evolution upgrades one eligible individual, preserves its passive and unlocks a signature. Successful reward grants up to 8 health and refreshes encounter budgets.

## Validation boundaries

The title does not start gameplay until Play. A stack owns the active screen and restores focus: menu → codex/options/help; battle → pause → options; battle → inspection/reward/replacement/result. Back pops one layer. Leaving an expedition requires explicit confirmation. Semantic controls have explicit focus neighbors; all input paths share the same rules. A busy guard prevents duplicate casts during feedback; an epoch token cancels stale callbacks after a session ends.

`rules.state_changed` drives the HUD; only visual interpolation/idle/effects run each frame. Selection keeps card nodes alive. Visual RNG is separate from combat RNG. Reduced motion clears current effects and updates existing cards/actors. Flashes default off. Large text rebuilds views and restores semantic focus. SFX voices (4) and particles (64) are bounded. Graceful shutdown stops audio streams before engine exit.

The numerical rule suite is independent of UI and includes fixed expected values for all traits, passives and evolved signatures. It checks rejected actions, deterministic seeds, replacement, stable rolls and power conservation across 100 complete simulations.

`tools/check.sh` preserves exit codes, rejects Godot script errors, verifies a nonzero executed assertion count, and checks real scene startup. `tools/mutation_smoke.py` runs isolated temporary copies with two deliberate regressions; tests must fail behaviorally without crashes. It never edits the real project.

The browser harness operates real controls in the exported Web game. Its read-only bridge is enabled by `?test=1`; it exposes no mutation methods. Input/Control acknowledgement counters synchronize actual input. `&visual=1` freezes ambient idle motion only. The plan exercises capture/evolution and alternate full-team replacement. It checks deterministic rule state, illegal energy, persistence, focus, modal layers, layout, titles and solid-button text contrast. This validates integration; it does not replace independent expected-value tests.

`tools/iterate.py` runs rules/UI, Web export and the browser matrix, records source hashes, preserves each timestamped attempt and generates a comparison gallery/notes form. See `docs/iteration-harness.md` and `docs/ux-contracts.json`. Automated passes never constitute aesthetic approval or a proof of fun.

Browser rendering uses software WebGL in the cloud. Native Linux startup is checked headlessly. Windows export is not Windows execution. Hardware performance, subjective fun and Steam integration are not established by these tests. CI must not be reported as remotely passed until a real GitHub run exists.

## Conventions

Use explicit GDScript types at public boundaries. Keep randomness local, seeded and outside preview. Keep copy in Portuguese through native text/tr calls. The 1600×900 reference canvas expands across aspect ratios; controls anchor to edges/centers and flow through containers. Desktop is the target. New content goes in the catalog; new mechanics require behavioral tests; UI changes require the iteration harness and rendered review. Record asset provenance and retain font licenses in distribution bundles.

Avoid unrelated backends, plugin systems and analytics stacks. Read the local Umbral skill for the development workflow.
