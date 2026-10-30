# Architecture and behavior contracts — collective battle slice

The working tree integrates the first v0.4 battle slice while the product version remains 0.3.0. Acceptance/evidence is recorded in [the implementation note](battle-implementation-v0.4.md); this does not declare the whole 0.4 milestone complete.

## Responsibilities

- `scripts/content.gd`: species, stage names/art, unique traits, useful passive pools, power definitions, signature unlocks and enemy intention patterns.
- `scripts/rules.gd`: deterministic state machine, individuals, owned power instances, persistent owned card zones, speed initiative, individual HP, target slots, status effects, substitutions and rewards.
- `scripts/main.gd`: session coordinator, screen construction, feedback events, local statistics and opt-in read-only browser state.
- `scripts/ui/`: screen stack, named input, atomic preferences, theme/buttons, persistent cards/hand, actors, world, health display, bounded effects and audio.
- `scripts/assets/`: exact production resource bindings and version-explicit animation loading. Assets are independently versioned modules; gameplay content stores logical art IDs. See `docs/assets/README.md` for ownership, immutable releases, authoring and CI validation.

The tactical revision delegates pure combat helpers from `rules.gd` to
`scripts/battle/`: `targeting.gd` is the single source for slot masks and eligible
targets, `initiative.gd` builds both the public player commands and committed
queue with one comparator, and `enemy_planner.gd` commits catalog patterns and
target policies once per round. These modules never access scene nodes; preview
and command projection do not consume RNG. The rules facade still owns state,
validation and effect resolution. See [the revision](battle-tactics-review-v0.4.md).

`ui/battle_hud.gd` owns battle composition and emits semantic commands without
reading rules. `ui/battle_plan.gd` receives only player entries and public bodies,
emitting target/removal requests. Main coordinates them through the existing
screen stack. Card identity fingerprints exclude transient target fields, so
target edits preserve nodes; owner data refreshes after actual state changes.

There are no network services, credentials or analytics endpoints. JSON gameplay logs go to stdout. Saves contain completed runs, wins, best applied damage and a separate validated preferences file. No personal data is collected. The Godot project lives at the standalone repository root. The legacy native user-data location is preserved so moving the source does not reset existing saves.

`scripts/storage.gd` stores small JSON records atomically on desktop and synchronously in browser `localStorage` on Web. Web `FileAccess` writes depend on an asynchronous IndexedDB sync; navigating immediately could otherwise restore an older record. Preferences and statistics have separate versioned keys. Existing Godot files remain readable as a fallback for migration, and callers validate loaded fields before applying them. Storage errors leave the current session usable and emit a warning; they must not be described as a successful save.

## Individuals and content

Each individual has `uid`, `species`, `passive`, `stage`, `hp`, `max_hp`, `attack`, `defense`, `speed`, `block`, `statuses` and `slot`. Slots 0/1/2 mean upper/middle/lower; −1 means reserve. There are no rear ranks. A species trait is fixed; evolution preserves the individual's UID/passive and upgrades attributes/powers. Species stats and power definitions live in the content catalog.

A run begins with one central individual of the chosen starter species. The roster holds up to six individuals, with one to three active by choice. Captures explicitly choose a vacant field slot or reserve (D44). Formation can be edited explicitly between encounters; normal entry/switch during battle costs an action and commits with Conjurar. Do not infer extra attacks from active count.

Three initial powers contribute two copies each. Every card has a unique `instance_id`, `owner` UID and `power` ID. Evolution upgrades the same instances and does not add signature copies automatically. Encounter transitions persist edited compositions; releasing an owner removes their instances. Healthy reserve cards are suspended outside active zones. Returning draw cards uniformly interleave with the remaining draw sequence, preserving its relative order; discarded cards remain discarded until draw exhaustion. At exhaustion the normal recycle precedes interleaving, avoiding owner-only entry hands. Incapacitated owners remain in the cycle, blocked until able to act again.

## Combat contract

The base hand is six; explicit relic/individual modifiers can alter capacity. The prototype bounds hand capacity to 1–24 operationally; this is not a user-defined balance ceiling. Three shared actions pay variable power costs, swaps/entries and tactical items. There is no separate energy or fixed per-owner power limit. Compatibility fields named `energy`, `player_hp`, `enemy_hp`, `plays` are migration/display aliases, not additional resources or loss conditions.

Select cards, targets and optional swaps/items, then commit. Invalid owners, unknown powers, duplicate card instances, invalid targets and over-budget casts fail without spending rounds, HP or RNG. Preview aggregates the player's conditional power effects only; it never resolves or exposes hidden enemy plans. Public enemy views project hidden/partial/full information over the same committed plan. Settings apply to the next planning round and never replan the AI.

Resolution:

1. Validate the entire chosen plan, then build a canonical queue of both sides.
2. Explicit priority resolves first (prototype: switches/entries 100, items 90, guards 1, ordinary techniques 0), followed by current owner speed and stable seeded owner ties. Same-owner techniques use catalog order then instance ID; click order has no effect.
3. Each effect sees state left by earlier effects. Water applies Wet; eligible lightning doubles damage only if Wet already exists. Normal damage uses power + attack −10, then modifiers and target defense; block absorbs it. These are prototype formulas.
4. Targets refer to stable slots. Individual, upper+middle, middle+lower and all-position masks keep their meaning with vacancies. An incoming substitute receives the original slot's attack. Taunt redirects eligible individual attacks, not areas, without rewriting the committed plan.
5. An incapacitated or withdrawn owner does not execute remaining powers. Revive restores HP but makes the owner eligible only next round. Events carry public target snapshots so presentation can update each actor at the corresponding impact without mutating rules.
6. End-of-round burn ticks and decays; temporary statuses advance. All hand cards, selected or not, enter discard. Recycle discard only when draw is exhausted; never duplicate current hand instances.
7. If no roster member can continue, lose; if all enemies fell, offer rewards/victory. There is no arbitrary seven-round defeat. KO replacements happen after the complete queue for free, without forcing three actives or cleaning blocked owner cards.
8. Draw the next normal hand and commit the next enemy plan. Incoming owner cards enter only at this draw; no free immediate draw or global reshuffle from planning a switch.

Resortear skips the entire round, with no selected powers, switches or items executed; enemies resolve their committed actions and the full hand renews. Consulting the backpack is free. Potions/revive are external consumables; current examples cost one action and are spent only on resolution.

Consumable definitions, costs and initial stock live in `content.gd`. Item and
swap selectors use rule-provided eligibility reasons. The player can edit/remove
commands via the Plan panel, clear all pending commands, and inspect grouped
draw/discard contents without revealing draw order. Own-command ordering is
conditional: opponents interleave, and same-speed owner ties are sampled only
at commitment. No private enemy timeline or future HP appears in this panel.

Enemy preparation stores visible `charge`, consumed once by the next damaging
technique and applied equally to that technique's area targets. It persists
through non-attacking rounds. The full intent projects power including stored
charge; hidden/partial projections keep their existing information boundaries.
Target policies such as weakest-active run at planning time, without examining
player selections; subsequent substitutions still receive slot attacks.

## Rewards and transitions

`battle → reward → battle → reward → battle → victory`; a battle can end in defeat or pause for between-round KO replacement.

Offers/passives are rolled once. Cancelling dialogs does not reroll them. A capture into a full roster requires an explicit outgoing UID. Evolution preserves current HP proportion, individual identity and edited copies, with no implicit full heal or extra signature cards. Map/shop/profile progression and a resumable active-run save are later slices; current storage persists preferences and completed-run statistics only.

## Validation boundaries

The title does not start gameplay until Play. A stack owns the active screen and restores focus: menu → codex/options/help; battle → pause → options; battle → inspection/reward/replacement/result. Back pops one layer. Leaving an expedition requires explicit confirmation. Semantic controls have explicit focus neighbors; all input paths share the same rules. A busy guard prevents duplicate casts during feedback; an epoch token cancels stale callbacks after a session ends.

`rules.state_changed` drives the HUD; only visual interpolation/idle/effects run each frame. Selection keeps card nodes alive. Visual RNG is separate from combat RNG. Reduced motion clears current effects and updates existing cards/actors. Flashes default off. Large text rebuilds views after any committed event stream finishes, then restores semantic focus; inspection is blocked during feedback to avoid displaying advanced-model HP. SFX voices (4) and particles (64) are bounded. Graceful shutdown stops audio streams before engine exit.

Battle rendering frames the background against the visible arena above the dock, with a top-aligned horizon. Per-art `grounding` metadata in the atlas JSONs defines opaque foot pivots and footprint widths; PNG bytes remain untouched. Idle scaling pivots on those feet, with anatomical contact shadows. A small depth scale/tint by lateral slot affects the portrait only; labels, hit areas, logical slots, targeting and combat stats stay independent.

The numerical rule suite is independent of UI and includes fixed expected values for all traits, passives and evolved signatures. It checks rejected actions, deterministic seeds, replacement, stable rolls and power conservation across 100 complete simulations.

`tools/check.sh` preserves exit codes, rejects Godot script errors, verifies a nonzero executed assertion count, and checks real scene startup. `tools/mutation_smoke.py` runs isolated temporary copies with eight deliberate regressions; tests must fail behaviorally without crashes. It never edits the real project.

The browser harness operates real controls in the exported Web game. Its read-only bridge is enabled by `?test=1`; it exposes no mutation methods. Input/Control acknowledgement counters synchronize actual input. `&visual=1` freezes ambient idle motion only. The plan exercises capture/evolution, reserve deployment and an alternate actual 3×3 path. Full-roster release has a separate numerical fixture; three encounters cannot naturally capture six members. It checks deterministic rule state, illegal shared action cost, persistence, focus, modal layers, layout, titles and solid-button text contrast. This validates integration; it does not replace independent expected-value tests.

`tools/iterate.py` runs rules/UI, Web export and the browser matrix, records source hashes, preserves each timestamped attempt and generates a comparison gallery/notes form. See `docs/iteration-harness.md` and `docs/ux-contracts.json`. Automated passes never constitute aesthetic approval or a proof of fun.

Browser rendering uses software WebGL in the cloud. Native Linux startup is checked headlessly. Windows export is not Windows execution. Hardware performance, subjective fun and Steam integration are not established by these tests. CI must not be reported as remotely passed until a real GitHub run exists.

## Conventions

Use explicit GDScript types at public boundaries. Keep randomness local, seeded and outside preview. Keep copy in Portuguese through native text/tr calls. The 1600×900 reference canvas expands across aspect ratios; controls anchor to edges/centers and flow through containers. Desktop is the target. New content goes in the catalog; new mechanics require behavioral tests; UI changes require the iteration harness and rendered review. Record asset provenance and retain font licenses in distribution bundles.

Avoid unrelated backends, plugin systems and analytics stacks. Read the local Umbral skill for the development workflow.

## Elemental slice V04-BAT-03A

`battle/conditions.gd` owns the explicit condition definitions, numeric counter
application/refresh/consumption and round decay. Source UID/side live separately
in `status_sources`; sources never follow slots. `battle/reactions.gd` selects
one sparse, ordered reaction from pre-hit state without mutating it. Rules owns
all effect application and events. The facade remains the single battle API.

Powers declare move nature, learning class and conditions. The legacy summary
fields `burn`, `wet`, `taunt`, `lightning` are projections for existing callers;
the resolver uses the new condition/nature definitions. Owner nature and
species resistances are independent catalog data. Power potency, offensive
weakening, reaction and nature resistance multiply before a single floor;
Defense then shield then HP follow. Burn ticks retain their bypass behavior.
Charge and Interference consume once per attacking technique, before iterating
its target mask. No automatic condition resistance, STAB or dual-nature cards.

Starter selection does not call rules or roll passives until a choice commits.
The same seed/species reproduces the run. Curated two-capture routes expose the
prototype reactions without a debug team; shops/learning remain future work.
Public inspection uses projected bodies and source data; hidden/partial plans
never expose upcoming move nature or conditions. Attack events carry the
executed move's nature for visual effects. See [the exact contract](natures-status-reactions-v0.4.md).

## Battle readout V04-BAT-04A

`ui/battle_readout.gd` formats only own planned actions and resolved public events.
The HUD owns a bounded three-button command strip; extra commands route to Plan.
Names, original round/encounter and cancellation reasons are captured with events,
so history survives lineup changes without projecting private future plans.
Modal teardown hides first and queues destruction at frame end, preserving Godot
input dispatch for touch. See [scope and evidence](battle-closeout-v0.4.md).

Free KO replacement also runs at encounter start for partial KO lineups.
Declined replacement UIDs are encounter-local state, cleared on encounter change
and revival; a new KO or the loss of the last active can prompt recovery again.
The choice suppresses repeated modals, not blocked cards or the recovery path.

V04-BAT-04B keeps a declined KO slot available to ordinary paid swaps. The
queue validator and resolver both preserve the KO owner and its blocked copies,
while the incoming body receives committed slot attacks. A revive restores HP
but never deploys a reserve automatically.

## Expedition and checkpoint boundary (V05-RUN-01 / V05-SAVE-02)

`scripts/expedition/expedition.gd` owns navigation through a fixed small fork,
node eligibility/completion and one authoritative `Rules` instance. It does not
copy the party into another competing run state. Catalog encounter IDs select
battles; numeric encounter remains a compatibility/display field. In expedition
mode, rewards return to map. Explicit practice keeps the original sequential
combat path. See the [implementation contract](expedition-contract-v0.5.md).

`ui/expedition_map.gd` receives a copied public snapshot and emits selection,
confirmation/pause/formation requests; it never accesses gameplay RNG or writes
battle state. Main is the sole screen/save coordinator. The three-column fork
uses containers, scrolling, focus and roster wrapping.

`expedition/run_save.gd` stores two versioned, checksummed generations separately
from preferences/statistics. Native writes use atomic temporary files; Web writes
are read back synchronously. A completed ID journal in the profile guards result
idempotence. Confirmed replacement retires the prior backup; an unavailable
storage path is reported without pretending a new run was saved.

Snapshots preserve canonical copies, zones, individual statuses, exact RNG strings,
committed intents and offers. Restore validates a detached candidate, then commits
it atomically; it clears only uncommitted selections/swaps/items. The browser
bridge exposes the controller public view, never its private checkpoint/enemy plan.
The map is a fixed prototype fork, not procedural biome generation. Merchant,
learning, acquired relics and broad events remain later slices. Validation and
remaining scope are recorded in the [expedition delivery note](expedition-implementation-v0.5.md).
