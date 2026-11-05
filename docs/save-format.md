# Expedition persistence compatibility

The expedition is separate from the permanent profile. Checkpoints use two alternating slots, each an `umbral.expedition.checkpoint` envelope with version, generation, kind, snapshot, compatibility identity and SHA-256 checksum over its JSON payload. A completed clear writes a newer tombstone before removing either slot. Checksum damage and interrupted writes can recover the older slot; an unknown envelope, snapshot schema or compatibility identity blocks loading, saving and clearing to protect data produced by another version. `last_status` distinguishes `incompatible`, `corrupt`, `io_error`, `recovered`, `missing`, `cleared` and `ok`.

Snapshot schema 2 records the ruleset identifier and a deterministic digest of the gameplay catalog, together with canonical species and form IDs. A change to deterministic rules requires a ruleset bump; changes to the catalog included in the identity change the digest. Restoring validates a detached candidate before replacing the live run. RNG seed and state remain decimal strings so JSON cannot lose 64-bit precision. Card instance IDs, owners, zones, passives, committed enemy plans and pending reward choices are preserved.

Envelope version 1 and snapshot schema 1 are read as legacy data. Migration maps each numeric stage through the explicit species mapping and resolves each pending evolution to its unique source, target and transition. Unknown forms or ambiguous transitions fail closed; migration does not rewrite the source slot. A subsequent normal save writes version 2. Schema 1 does not carry an identity, so its adapter is pinned to the audited ruleset and gameplay digest. The explicit registry transition can then admit a verified additive catalog; other changes require a reviewed migration decision.

Replay decoding validates a detached expedition candidate before accepting a checkpoint. Replay envelopes use `umbral.expedition.replay` version 2, the same compatibility identity, an initial schema 2 checkpoint and an array of whitelisted commands. Legacy unversioned `{initial_state, commands}` recordings are accepted only with schema 1 initial states and go through the same migration. Replays cannot set arbitrary game state or RNG. Unsupported versions and identities are rejected before execution.

The compatibility registry pins an audited gameplay manifest to the schema 2 identity from `6e1b2ed`. A source identity is accepted only when it is current or has an explicit registry entry. The registry verifies the pinned manifest's digest and allows an additive transition only when every existing species, form, power, passive and encounter definition remains equal, encounter and species order remain prefixes, and every existing pool, route and other gameplay extra remains equal. New species and their passive pools, powers, and consumables may be added without changing existing selections. Manifest version 2 also binds each item ID to its effect ID. The audited old manifest lacked those bindings, so its explicit adapter supplies the historical potion/heal and revive/revive mappings before comparing it with the current manifest; the new digest is intentionally different. This conservative rule preserves the random choices and numeric encounter indices of existing expeditions; changing an existing definition, selection pool or ordering requires an explicitly reviewed migration or ruleset decision. Cosmetic fields are excluded by the gameplay projection. Unknown identities and future versions still block loading, saving and clearing.

Migration operates on a detached copy and updates its identity only after an audited transition succeeds; repeated migration is idempotent. Schema 1 first uses its pinned adapter and then the same registry transition. Checkpoint and replay envelope identities must agree with the enclosed schema 2 snapshot, preventing mixed lineage. The registry's frozen source data is part of the game, never supplied by an untrusted save. A new registry entry must pin an audited source manifest and define an ordered, behavior-preserving path; it must not merely replace a digest. The two-slot checksum, generation and tombstone rules continue to apply across migrations.


## Rules 3: contextual spring, preserving rules-2 runs

V05-EVT-01 explicitly bumps the ruleset to `expedition-rules-3`. Schema 2 now
requires integer `event_revision` (0 or 1). New runs use 1 and persist a stable
`event` phase at the spring, with battle remaining on the map and empty zones.
The event command either applies the existing rest or transfers one physical
copy between known techniques of one living owner; drafts are never persisted.

Migration accepts the pinned rules-2 main identity
`7df20eb40243b3b48a76c0ddee5eaa46321984f49612f36a59684e75cb673e80`
and the existing audited baseline, verifying their frozen gameplay manifests
through the conservative additive comparator. Both migrate to revision 0:
old expeditions retain immediate spring healing and unchanged reward generation.
The current rules-3 identity continues to carry revision 0 on subsequent saves.
The legacy schema-1 adapter follows the same path. Historical identities cannot
contain the new event phase or opt into revision 1. Unknown identities stay blocked.

The frozen main replay fixture records real pre-change commands and expected
checkpoints. Tests compare normalized complete snapshots after two encounters
and the old rest alternative, including RNG, plans, rewards and physical cards.
Replay envelope version 2 and checkpoint envelope version 2 remain in use with
the explicit new compatibility identity; unsupported versions still fail closed.

## Rules 4: explicit catalog revision for final grass forms

The playable Foslash slice uses `expedition-rules-4`, retaining checkpoint,
replay and snapshot version 2. A schema-2 snapshot now requires integer
`catalog_revision`, stored once at expedition level and installed on its one
Rules instance. Revision 0 retains the previous evolution graph; revision 1
added form `foslash` and edge `verdalio_to_foslash`. New runs now use revision 2,
also adding `folivel` and edge `verdalio_to_folivel`. This is separate
from `event_revision`, which still selects only the spring behavior. Existing
species `moss`, forms `moss` / `verdalio` and edge `moss_to_verdalio` stay stable.

The registry explicitly pins the rules-3 identity with catalog digest
`7df20eb40243b3b48a76c0ddee5eaa46321984f49612f36a59684e75cb673e80` to the
already frozen rules-2 gameplay manifest: those rulesets have the same catalog.
Its reviewed transition removes only the registered appended Foslash form/edge
and corresponding derived projection entries before applying the unchanged
conservative comparator. Changed historical stats, edges, pools or ordering
still reject migration; arbitrary extra final forms/edges are not admitted.
No manifest is accepted from save data and no unregistered digest is trusted.

Rules-3 snapshots retain their event revision (0 or 1) and migrate to catalog 0.
Schema-1 and both pinned rules-2 identities retain event revision 0 and likewise
use catalog 0. Migration remains detached and idempotent. Historical identities
cannot claim a new catalog revision or contain its forms, captures or pending
evolutions. Under the current identity, a revision-0 run still rejects a forged
Foslash body/offer. Reward generation, command application and checkpoint restore
all use the same revision query. Replays use those production command boundaries.
Unsupported catalog revisions block load, overwrite and clear through the
existing envelope validation. Ordinary reads never rewrite historical slots.

The frozen rules-3 moss fixture records 59 real commands, the actual Foli-to-Folife
choice, both encounters and their full pending rewards, plus a spring alternative
and an actual checksum envelope. Tests preserve RNG, plans, card identities/zones
and offers. Foslash provisionally repeats only the existing Foli-to-Folife
numerical delta: HP/attack/defense/speed 72/14/6/12, living_roots 6, power profile
damage/block/heal/burn/wet 10/8/4/2/2. Existing card instances improve without new
power IDs or copies. These are revisable prototype values, not final balance.
This adjustment affects only the new form available in catalogs 1/2; historical catalog-0 values
and fixtures are unchanged. Its own art/VFX do not authorize new mechanics.

## Catalog 2: preserve committed Foslash runs while adding Folivel

The exact catalog-1 gameplay manifest from `c7f9ec1` is frozen in
`expedition/catalog1_manifest.gd`, pinned to rules-4 digest
`07942959b491e5c9466c7133b0a4b1809283f9aee7162d405af6ff31aa278442`.
Its saves already require `catalog_revision` 0 or 1; migration preserves that
value and its spring revision, rather than selecting 2. The old identity cannot
claim revision 2 even when its party contains only an initial form. Boolean,
string, fractional, missing and future revisions fail closed before migration.
JSON's integral numeric 0/1 values remain accepted at the historical boundary.

The extension adapter removes only registered appended suffixes, in reverse
order: Folivel then Foslash for source catalog 0, and only Folivel for the
catalog-1 manifest. The original conservative comparator then verifies every
published definition, including Foslash. Both forms and corresponding projection
entries remain explicitly ordered. An unregistered digest, form/edge/order or
rewritten existing definition does not gain admission through the adapter.

Current-identity runs retaining catalog 1 still reject Folivel bodies, captures,
pending offers and injected commands/replays. Catalog 0 also rejects Foslash,
including under the frozen catalog-1 source identity. Only a new run selects
catalog 2 and sees the second final branch. Folivel provisionally shares Foslash's
72/14/6/12 attributes, living_roots 6 and 10/8/4/2/2 profile; no new power IDs,
card copies, canonical specialization or further evolution are introduced.

Before the addition, a real catalog-1 replay recorded 61 production commands
through the Foslash choice and next boss encounter. A real catalog-0 run migrated
under that same rules-4 identity records 59 commands and its capture-only second
reward. Their complete checkpoints, cards, offers, plans, RNG, source manifest
and actual checksum envelope are frozen as independent migration fixtures.
