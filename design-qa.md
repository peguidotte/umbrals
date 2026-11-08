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
- [P2, fixed] In browser-06 800×600, Opções crossed
  the top of the ruin. The title shader now extends the sky only for the middle
  layout, below the complete actions/notice band. The new source passes focused
  UI/regression checks. The later 800×600 capture in the interrupted
  `live-title-final-browser` attempt was opened and shows clear sky behind it.
- [P1, fixed, final matrix pending] Direct inspection of that attempt found
  clipped Options at 320 px and blurred locally enlarged text. The view now
  uses local font copies with appropriate raster density, wrapped toggle
  captions, compact margins, field-aware slider reveal and content-sized mode
  buttons. The mobile probe's 390 px, 320 px enlarged-text and secondary-link
  images were opened; text is sharp and the panel fits. Native regression adds
  width/clearance assertions at 320, 390, 800, 1024 and 1280 px. The failed
  images and the interrupted attempt remain preserved.
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
post-polish menu captures/videos are recorded in `test-results/live-title-review-proof`.
The final polish adds a 220 ms nonblocking exit fade and bounded local reaction
effects, with reduced-motion/flash suppression. It requires final playback
inspection along with the dribble.

The subsequent `live-title-final-proof` attempt exposed an intermittent folded
battle-VFX ribbon triangle rejected by the renderer despite its area guard.
The ribbon now checks actual triangulability before drawing that sliver. Motion,
settings, title, UI flow and architecture passed in `live-title-geometry-fix`.
That interrupted attempt is preserved; it is not represented as full acceptance.

The later title scenario passed 174 checks and supplied the inspected 320/390 px
Options captures, with sharp text and contained geometry. A navigation timeout
exposed unnecessary copying of the codex's cached font bitmaps. Clean definitions
are now shared only within Options; its normal/large navigation scenario passed
unchanged in `live-title-font-navigation`. Latest title/expedition captures use
`test-results/live-title-candidate-proof`; all prior attempts remain separate.

A convenience copy of selected final proof may be placed in
ignored `test-results/live-title-delivery`; this does not replace original evidence.
No claim of final visual acceptance is made while this report is blocked.

Final scoped evidence: title 174, navigation 160, expedition 417 passed. The last
expedition change fixed its clipped-control click helper; both complete routes
and all final enlarged-text assertions ran again. Idle after 30 modal cycles
preserved 44 nodes/10 audio children and save/RNG for 605.6 s. Native Linux Quit
exited 0 without warnings using an owned test watchdog. Selected evidence is in
`test-results/live-title-delivery`; per-report hashes/runtime equivalence are
recorded there. Source overlay and human art review remain blocked/pending.
Foreground foliage is static. Windows/DPI and physical-device checks were not
executed; full repository acceptance is still open.
