# UI/UX baseline captured before the v0.3 redesign

Source: a fresh successful Chromium playthrough of v0.2, captured in this task. Files are retained under `test-results/baseline-v0.2/`. This is a review of the rendered Godot canvas and actual interaction, not a claim of full accessibility compliance.

1. **Entry — needs redesign.** `01-umbral-battle.png`: the game starts inside combat with two preselected creatures and no title/menu. A new player immediately faces rules and dense copy. Add a title screen, clear primary action, settings and accessible help.
2. **Combat and selection — works, visually weak.** `05-umbral-boss.png`: preview, energy and enemy intention are useful. Two large side rails and stacked rectangular panels dominate the screen; characters occupy little space. Small effect/passive text risks becoming unreadable when scaled. Put characters in a clearing, attach enemy health/intention to the opponent, make the hand the primary interaction and move full trait text into inspection.
3. **Capture/evolution — works, needs hierarchy.** `04-umbral-evolution.png`: choices expose the offered individual and preserve passives. Four equal cards require reading everything. Strengthen capture/evolution labels, portrait scale and unlocked-power callouts, while keeping explicit replacement/cancellation.
4. **Result — works, lacks rhythm.** `06-umbral-victory.png`: replay and new seed are available, but actions resolve almost instantly throughout the run. Add anticipation, short impact effects, animated bars/numbers and distinct capture/evolution/victory cues.

The old harness verifies numbered keyboard shortcuts, not a complete focus-navigation flow. Inspecting the code confirms the control tree is recreated on each selection, which makes stable focus difficult. The next version must use persistent HUD controls, named input actions, initial focus, explicit neighbors and a modal state stack.

Priority: menu/pause → arena/HUD hierarchy → hand readability/inspection → feedback → multi-resolution, focus and reduced-motion verification. Beauty and fun require visual/playtest judgment; screenshot counts cannot certify them.
