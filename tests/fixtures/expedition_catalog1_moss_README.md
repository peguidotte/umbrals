# Frozen committed catalog-1 lineage

Captured before adding Folivel from `c7f9ec18ad2d218a5ffaf354472e2bf01197c07c`,
Godot 4.6.3, rules-4 identity
`07942959b491e5c9466c7133b0a4b1809283f9aee7162d405af6ff31aa278442`.
The complete manifest is frozen in `scripts/expedition/catalog1_manifest.gd`;
its internal JSON digest was verified against that identity before source edits.

`expedition_catalog1_moss_replays.json` contains:

- Catalog 1: new seed-1/moss/partial run, 59 actual whitelist commands to the
  second reward, the actual Foslash reward choice and boss entry (61 commands).
  Pending reward, chosen form and boss checkpoints are complete.
- Catalog 0: actual migration of the previously frozen rules-3 initial run into
  committed rules-4/catalog0, followed by its 59 production commands. The second
  reward remains capture only.

All captured checkpoints restored exactly before the catalog changed. No unit,
catalog or RNG setters were used; source hashes before/after matched. Replay SHA:
`55acfb697a677e9746964e1165d81fd0c930e6453774412bdf265587f5c0bb4f`.

`expedition_catalog1_moss_checkpoint.json` is the actual RunSave generation-1
envelope at the catalog-1 second reward, retaining its original checksum. SHA:
`e1b92d22ba8559f3e16d227acac4855357573d0a25d9c5c18fd84b077fa6e324`.

These are fixtures of the committed source catalog, independent of Folivel's
implementation. Earlier schema-1/rules-2/rules-3 fixtures remain unchanged.
