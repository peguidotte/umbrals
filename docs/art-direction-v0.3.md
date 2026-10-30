# Visual target — moonlit botanical ritual

The user delegated the redesign. The selected direction preserves the existing original creature/power silhouettes and puts them in an illustrated clearing, replacing the dashboard composition.

- Engine: Godot 4.6.3, Compatibility renderer; desktop and Web.
- Reference: 1600×900, expanding canvas; anchors/containers keep critical UI inset from screen edges. Verify 1280×720, 1440×900, 1920×1080, 1024×768 and ultrawide.
- Environment: blue-green forest, layered silhouettes, subdued texture, moonlight from upper right; low-detail lower area for cards.
- Palette: parchment `#f3e6c5`, antique gold `#dec88d`, ink `#101c23`, secondary text `#bac6b6`; fire/jade/lightning keep their species colors.
- UI: sharp ornamental frames, engraved labels, rune-shaped highlights and energy gems. Dynamic text stays native, never painted into an image.
- Composition: protagonists on the left, enemy on the right, spatial enemy health/intention, compact corner HUD, hand in a shallow fan near the bottom. Full traits/passives live in inspection and reward screens.
- Motion: eased hover/selection, brief anticipation, importance-scaled impact, floating damage and restorative effects. All effects return to rest; reduced motion/flashes are options.
- Art asset: `assets/world/moonlit-clearing/versions/1.0.0/background.png` (migrated from `assets/world/clearing.png`), original Image Gen output, 1672×941 RGB. Preserve the source file and metadata; use aspect-cover in-engine, without image cropping/editing.
- Texture budget: background under 3 MB encoded / about 6 MB uncompressed; original SVG portraits/icons remain separate. Filtering is linear; inspect at game scale and all capture resolutions.
- Acceptance: readable against the actual forest, visible focus without color alone, no clipped actionable controls, short effects without duplicate actions. No generated labels, logos, commercial game art or unrelated visual families.

Source generation prompt and provenance are recorded in the asset manifest. Source inspection passed; in-engine approval is recorded after the new capture matrix succeeds.
