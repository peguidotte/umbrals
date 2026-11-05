# Frozen rules-3 moss expedition

Captured from `b708c910d8eaaf0f281a6cc616d5fdae99907cfa` before the final-form
mechanics changed, Godot 4.6.3, seed 1, partial information, starter `moss`.
All actions used production replay-whitelist commands. No unit/stat/RNG/catalog
mutations or alternate fixture boot were used. Source hashes before/after matched.

`expedition_rules3_moss_replay.json` includes 59 actual commands through clearing,
choice of `moss_to_verdalio`, and thicket's reward. The historical second reward
has only a capture. It also retains the clearing reward, post-evolution map and
the alternate contextual-spring rest commands/result (`event_revision = 1`).
Expected full snapshots retain RNG strings, plans, cards, zones and pending offers.

Replay fixture SHA-256:
`fd00692856e03d2a87b0c432b1f4b1ec7cc287e2dbba7712af54b01ee5fe9d35`.

`expedition_rules3_moss_checkpoint.json` is an actual generation-1 envelope
written through `RunSave.save(pending_reward)`, including its original checksum.
SHA-256: `c8509c7655ffe8ac8f62c2aef18a1029bf3e9711f313fbfb63ef7d4839aee84b`.

Both use `expedition-rules-3` with gameplay manifest digest
`7df20eb40243b3b48a76c0ddee5eaa46321984f49612f36a59684e75cb673e80`.
That exact manifest is already frozen in `scripts/expedition/rules2_manifest.gd`;
rules-3 changed spring behavior, while leaving the gameplay catalog identical.
Earlier schema-1/schema-2/rules-2 fixtures are retained unmodified.
