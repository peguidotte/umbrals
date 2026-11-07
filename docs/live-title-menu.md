# Layered dusk title menu — implementation candidate

The user supplied the approved image directly in the implementation conversation
on 2026-11-07, after Library byte transfer was blocked by network policy. Its
pixels were viewed in that conversation. The implementation uses that visual
reference and the complete `menu-umbral-spec.md` (Library identity
`libfile_680ef2a885208191806d7111558f4ff4`). Work began from freshly fetched main
`f29752cac7d6525865091896a1466eb65a490c9c` in the existing checkout.

## Implementation

- Four native primary actions: Continuar, Novo jogo, Opções, Sair. Web omits
  Sair and recenters the remaining controls. The legacy `menu.play` semantic ID
  now identifies Novo jogo; Continue has its own ID. Consumer tests were migrated.
- Public checkpoint availability/status comes from the session coordinator.
  Continue reuses `ExpeditionFlow.resume`; New reuses `RunFlow.choose_starter`.
  Incompatible saves disable New. Confirmation and starter cancellation preserve
  the saved run; choosing a starter remains the commit point. Stale starter
  activations are rejected after the screen changes.
- Options retains its real preferences. Secondary links expose Grimório,
  Como jogar, Créditos, Treino de batalha, and the existing Abrigo. Adding Abrigo
  is an execution decision to preserve the walkable home, rather than deleting
  that existing feature. Secondary Back returns to Options and restores focus.
  These links are exclusive to title Options, not nested battle Options.
- Layout uses measured native text and physical target minima, with a centered
  ultrawide stage, grid/column reflow, scroll-following focus and independent
  portrait/ultrawide environments. Back remains outside the Options scroll region.
- Options uses local font resources so a locally enlarged panel does not enlarge
  glyphs rasterized for the smaller root canvas. Captions wrap independently of
  switch icons; the volume field's label follows its slider into view. Compact
  margins and mode heights adapt to content rather than clipping it. Native
  enlarged-text checks cover 320, 390, 800, 1024 and 1280 px widths.
- Independent actors use sixteen normalized frames each: eight idle and eight
  reaction poses. Decorative clocks do not use gameplay RNG. Reactions have a
  cooldown and cannot queue indefinitely. Modals suspend input/processing; hidden
  title animation does not accumulate time. Reduced motion rests current actors,
  the water shader, and the orb.
- Lonlon's paw frames and orb use one clock, including the three reaction bounces.
  The liquid orb compresses at contact; one bounded ripple is drawn at contact.
  No decorative input writes a checkpoint or starts a run.
- Navigation commits immediately while the outgoing title fades for 220 ms.
  Its input and actor processing stop first; repeated actions cannot restart it.
  Reduced motion/capture bypass the fade; changing motion cancels it cleanly.
  Local reactions add three soft embers, one drifting leaf and a small electric
  arc. The arc is absent when flashes are disabled; all effects stop with motion.

## Art provenance and deliberate differences

The shipped pieces are **generated derivatives**, not the original approved PNG
and not animation clips supplied by the user. The original flattened image is
not drawn behind animated copies. Image Gen produced a clean scene, separate
logo, four pose atlases, water orb, support atlas, and portrait/ultrawide clean scenes.
The source PNG bytes and embedded metadata remain under the prototype release
`ui/living-title@0.1.0/review`, excluded from Godot imports. Runtime textures and
actor timing/pivots are independently pinned in `ui/living-title@1.0.0`.

Normalization slices even grids, removes alpha below 8/255, aligns baselines,
and repacks cells without repainting character RGB. The four actor cells are
320×320, four columns; supports use two columns of 768×256 cells. The manifest
records all hashes, byte counts, timings and pivots. Existing merged releases
and gameplay catalog definitions were not edited.

The generated logo is lighter than the first derivative and restores the crest
above the word. Character poses/silhouettes still differ from the approved
flattened illustration: the fire tail has a looser curl, the water actor is more
upright, and the electric actor has a narrower stance. These are reviewable art
differences, not a claim of exact pixel reproduction or human aesthetic approval.
The source contains 16 poses per actor; motion quality must be judged in playback.
No paid service, subscription, new music, or external stock art was purchased.

## Verification and remaining acceptance

`tests/title_menu_test.gd` exercises save-preserving cancellation, exact snapshot
resume, repeated starter activation, corrupt/incompatible/I/O state projection,
secondary routes/focus, decorative isolation, reduced motion, bounded reactions,
30 modal cycles, and audio teardown. Existing refuge, codex, options, expedition,
and input tests follow their actual new entry points. Browser diagnostics expose
clip visibility for scrollable controls; automation reveals them through real
Tab input instead of clicking clipped positions or adding production setters.

Run the required harness with frozen sources:

```bash
source tools/environment.sh
python tools/iterate.py --label live-title --goal 'Four native actions, independent dusk actors, save-safe continuation and responsive layout' --baseline test-results/live-title-preview --video
```

The title browser scenario captures saved and empty states at twelve requested sizes from 320×568 through
5120×1440, representative Options/reduced-motion states, real touch input, and
wide/portrait videos of at least 20 seconds. Its automatic results are recorded
in ignored immutable iteration artifacts. They are not aesthetic approval.

The `live-title-05` full attempt preserved a 1800-second timeout in the broad
four-route browser combat scenario. It was then interrupted during unrelated
house-layout coverage. All its native tasks and eight mutations had passed,
but it is **not a passing full gate**. Subsequent polish uses the focused native
and title/navigation browser reports in `test-results/live-title-final-*`.
The 220 ms fade and local effects passed the focused native regression first.
The first final-scope attempt then passed every native task, but visual review
found narrow Options clipping/blur that input checks had missed. It was
interrupted and preserved; the corrected final scope is
`test-results/live-title-final-proof`. Interim mobile probe images show sharp
text and a contained panel; final captures must still be inspected directly.
Final screenshots/videos need direct inspection; neither counts nor export
success constitutes visual approval.

The ten-minute Linux headless observation before the final local-effect/fade
polish held 44 nodes and 10 audio children and preserved save/gameplay RNG.
Its 52,832-byte memory increase includes retained observation samples; this is
not a GPU/hardware leak certification. A final-runtime repeat is recorded
separately when available.

Still required for final acceptance: execution on real Windows (including clean
Quit and 100/125/150/200% display scaling), hardware performance, physical
controller/screen-reader checks, audio listening,
and human review of the generated art and dribble. Linux headless startup and
Windows export must not be described as Windows execution. The 941-pixel-high
landscape source is scaled at 4K; native 4K illustration quality is not claimed.
The original Library PNG bytes remain unavailable for a numerical overlay;
visual comparison uses the user attachment. No merge, push, deployment or
workflow reactivation is authorized by this implementation.

The aggregate mutation budget is 1200 seconds for eight unchanged cases, each
capped at 120 seconds. The disposable fixture project has a 480-second cold
import budget inside its 600-second task budget. Initial attempts exceeded the
old aggregate 240-second, mutation-case 60-second, and import 180-second limits
on this four-core executor. No assertions or mutation cases were removed.

The pre-existing codex Back path now preserves its exact saved offset when the
viewport is unchanged; it avoids a redundant focus-reveal call that can round
scaled bounds and nudge the offset. A changed viewport still reveals the focused
control. The existing exact-scroll assertion is retained. Vertical grid navigation
also searches the intended row when Continue is disabled, rather than jumping
sideways to the lower row.
