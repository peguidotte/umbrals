# Species package migration — implementation and review

Completed: the three existing species and six existing forms now live in stable-ID packages.
No new playable species or newly drawn sprites were invented during this refactor.
See `adding-umbrals.md` for the authoring workflow and working `.tres` examples.

## Final executed evidence

`artifacts/species-packages-delivery-20261102T135550111930Z` passed the complete source-hashed
iteration: checks, actual Web PCK comparison, Web export, real browser input, video and all
five viewport formats. The prior acceptance/final runs and failed attempts are preserved.

- 5,892 original numerical/rule assertions, including 100 seeded simulations; both gameplay
  mutations remain detected behaviorally (12 and 3 failing checks).
- 565 domain/UI/lifecycle checks, including a three-level branched graph, power replacement,
  transition eligibility/cost/rejection, UID/passive preservation, frame playback, timed
  releases, all current form/direction/action combinations and a ten-species codex fixture.
- 30 package checks; 6 executed authoring assertions in a disposable project exercise creation,
  refusal, overwrite protection and successful append-only registration of a fourth species
  with three forms (four species/nine forms in that fixture).
- Two semantic comparisons load the actual exported PCK and compare all authored export
  fields and a seeded initial run with source. The browser independently checks initial
  species/form/passive identities.
- 98 production/data modules checked with twelve architectural negative cases rejected.
- 643 browser checks passed; the full five-format matrix executed (720p, 1440×900, 1080p,
  1024×768 and ultrawide), including enlarged text, persistence, focus and modal navigation.
- Web/Windows/Linux bundles exported and packaged. The final native Linux executable started
  and shut down without reported errors or leaked resources. Windows was exported, not run.
- Numerical action plans, hands, damage, energy, reward indices, replacement choices and
  outcomes remain equal to the pre-migration baseline. Runtime identity JSON intentionally
  uses `species_id` and `form_id`; there are no ongoing-run saves requiring migration.

## Findings resolved during verification

The first full attempt (`species-packages-20261102T131832119228Z`) found empty passive pools
in the exported game despite passing source tests. Native probing of the Web PCK reproduced
it; preserving text Resources through export restored all values. The PCK comparison and
initial-individual browser assertion now prevent recurrence. Conversion remains explicitly
disabled in project settings; changing that requires the exported-data gate to pass.

The hand-view cache previously used card instances alone. It now includes individual form
identity, so a new form updates stats even when it keeps the same power/instance IDs. A
regression proves the displayed fireball changes from 12 to 17 without changing the hand.
Capture descriptions also derive their power count from the form; a one-power fixture is
covered while the existing three-power copy remains unchanged.

The gallery's first render exposed overlapping origin labels and dim readonly text. Callout
labels, wrapping and text colors were corrected. Idle playback now follows its authored
clip duration; migrated clips retain their original approximate 4.49-second idle cycle.

## Rendered review

Inspected final codex, evolution rewards, battle, capture, boss/replacement and enlarged-text
4:3 captures. Menu, first battle, capture, boss and replacement captures were also
pixel-identical to the baseline, as recorded in `static-comparison.json`; this establishes
preservation of those images, not aesthetic quality or fun.

The codex keeps its portraits/traits with wrapping lineage text. Ten species and long
branches use a scrollable grid in the headless layout regression. Reward sets exceeding three
choices now use horizontal scrolling with focus following the selected control; the last
preview may be partially visible until scrolled. The scroll bar is visible in the four-offer
capture. This is the explicit layout tradeoff for growing branch counts.

Inspected gallery captures with real mouse selection of right, left and ranged attack.
The left preview visibly mirrors the tail, reports mirroring as true and shows distinct
origin labels. The ranged preview reports `mouth` at 0.10 seconds. Authoring notes explicitly
identify procedural states and original vector art. Gallery captures came from an isolated
Web export using the gallery as main scene; its components/resources are unchanged in the
final delivery. Release Web templates reject command-line scene overrides, so the preview
used a disposable project instead of modifying the real main scene.

Sampled the final recorded gameplay video around the first cast (`feedback-sequence.png`).
Selection rises, anticipation/projectile/impact feedback occurs, health resolves to the same
33/40 and 64/105 values, and controls return to rest. This is sampled inspection of actual
video, not exhaustive playback or a hardware-performance measurement.

Decision: accept the migration for the stated contracts and inspected experience. Current
forms use explicitly declared procedural clips and mirroring; the runtime also supports
actual frame lists, verified by texture-advance tests. Source asset bytes/provenance were
preserved. Physical controller, Windows execution, hardware audio/performance and subjective
fun remain separate validation tasks. No remote CI execution or publication is claimed.
