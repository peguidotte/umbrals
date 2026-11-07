# Menu visual QA — implementation candidate

final result: blocked

Source visual truth: the approved menu image supplied directly by the user in
this implementation conversation (displayed at 1280×721). The corresponding
Library identity supplied in the spec is
`libfile_f55fcf044ed081919dbe9c40c82e07ea`. The user attachment was viewed; the
original file bytes could not be materialized because its storage host was
blocked. No network-policy bypass or substitute reference was used.

Implementation evidence already opened:
`test-results/live-title-browser-06/tasks/browser.title/wide-live.png` (1600×900),
`menu-320x568.png`, `menu-390x844.png`, and `menu-800x600.png` in the same folder.
Chromium, deviceScaleFactor=1; game canvas captures, without browser chrome.
The wide source is approximately 16:9; the implementation is 1600×900.
Source density is not assumed to be 1×. The saved-state screenshots enable
Continue; the initial attachment depicts Continue selected. Web intentionally
omits Sair, while the native title has all four actions.

## Findings and iteration history

- The first generated logo put its ornament below the word and was too heavy.
  It was regenerated with the upper crest and lighter letters. The opened
  browser-06 wide capture shows this correction.
- Initial derivative actors were too small due to atlas padding. Cells were
  normalized to 320×320 with aligned baselines and the display size corrected.
  Browser-06 captures show four readable actors without duplicated bodies.
- Initial portrait crops placed village/ruin behind navigation. A separate
  portrait clean scene now provides continuous sky. Browser-06 320×568 and
  390×844 captures show the revised composition.
- [P2, fixed in code, final capture pending] In browser-06 800×600, Opções crossed
  the top of the ruin. The title shader now extends the sky only for the middle
  layout, below the complete actions/notice band. The new source passes focused
  UI/regression checks; the final iteration must supply post-fix images.
- The initial orb floated below the raised paw and sank below the rock at
  contact. High/contact positions and paw-frame selection were corrected.
  Browser-06's live wide capture shows the ball meeting the paw. Final playback
  must still be reviewed for dribble timing and generated-frame consistency.
- Portrait, 4:3 and ultrawide have explicit compositions. The ultrawide derivative
  extends scenery instead of cropping away foreground supports. Very narrow
  layouts prioritize native controls and can add a local support when the actor
  must move below a longer notice.

## Required fidelity surfaces

- Typography: native licensed Cormorant labels, warm ivory, dark outline/shadow;
  measured layout and physical minimum sizes. Generated logo is a derivative,
  with visibly different engraving/letter proportions from the attachment.
- Spacing/layout: action center is y=0.225 on the wide composition, implementing
  the requested upward move. Logo and actions are independently positioned.
  Portrait Web uses three centered rows; native portrait supports 2×2.
- Colors: blue dusk, pink horizon, green/gold foliage and warm gold logo preserve
  the direction. No opaque green rectangle covers the logo or actions. This
  review does not certify every rendered contrast pair or screen-reader use.
- Image quality: independent alpha atlases over a genuine clean plate; originals
  retained for provenance. Fire tail curl, upright Lonlon pose, electric stance,
  and generated facial/frame variations differ from the source. These are
  explicit art-review items, not claimed exact reproductions or approved art.
- Copy/content: Continuar, Novo jogo, Opções, Sair; the Web exception is documented.
  Empty/corrupt/incompatible/I/O notices are native text. Secondary functionality
  remains reachable in Options; no marketing/implementation copy was added.

## Remaining blockers to visual acceptance

A normalized combined source/implementation comparison and numerical overlay
could not be produced without the source attachment bytes. Separate views are
not represented as a side-by-side comparison. Human review of the regenerated
characters/logo and final dribble is still required. Windows execution/display
scaling and native aesthetic approval are also outstanding. Browser/headless
passes do not constitute aesthetic approval.

The `live-title-05` broad attempt hit its 1800-second combat-browser limit and
was interrupted during house-layout coverage. Its native passes are not a full
gate. The stable 1280×720 layout capture was opened and has the logo, primary
actions/focus and four actors. The very first integration capture omitted UI
while graphics were warming up; it must not be used as final proof. Final
post-polish menu captures/videos are recorded in `test-results/live-title-final-browser`.
The final polish adds a 220 ms nonblocking exit fade and bounded local reaction
effects, with reduced-motion/flash suppression. It requires final playback
inspection along with the dribble.

A convenience copy of selected final proof may be placed in
ignored `test-results/live-title-delivery`; this does not replace original evidence.
No claim of final visual acceptance is made while this report is blocked.
