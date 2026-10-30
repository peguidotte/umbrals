extends SceneTree
## Real Godot input events validate keyboard/controller routing without a physical pad claim.
var app: Control
var checks: int = 0
var failed: int = 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func key(code: int) -> void:
	for down in [true, false]:
		var event = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame

func pad(button: int) -> void:
	for down in [true, false]:
		var event = InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame

func focus_key() -> String:
	var node = root.gui_get_focus_owner()
	return node.get_meta("ui_id", "") if is_instance_valid(node) else ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	expect(focus_key() == "menu.play", "Title gives initial focus to Play")
	await pad(JOY_BUTTON_DPAD_DOWN)
	if focus_key() == "menu.continue":
		await pad(JOY_BUTTON_DPAD_DOWN)
	expect(focus_key() == "menu.practice", "Controller d-pad moves from expedition to practice")
	await pad(JOY_BUTTON_DPAD_DOWN)
	expect(focus_key() == "menu.codex", "Controller d-pad continues through title choices")
	await pad(JOY_BUTTON_A)
	expect(app.screens.top() == "codex" and focus_key() == "codex.back", "Controller A opens the focused codex")
	await pad(JOY_BUTTON_B)
	expect(app.screens.top() == "menu" and focus_key() == "menu.codex", "Controller B restores the previous menu focus")
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	expect(app.screens.entries == ["menu", "settings"], "Keyboard opens options from title")
	await key(KEY_TAB)
	await key(KEY_TAB)
	expect(focus_key() == "settings.reduced_motion", "Tab reaches reduced-motion without escaping the modal")
	await key(KEY_ENTER)
	expect(app.preferences.values.reduced_motion, "Keyboard toggles and persists reduced motion")
	await key(KEY_ESCAPE)
	expect(app.screens.top() == "menu" and focus_key() == "menu.settings", "Back from options restores title focus")
	app.registry["menu.practice"].grab_focus()
	await key(KEY_ENTER)
	await process_frame
	expect(app.screens.top() == "starter" and focus_key() == "starter.ember", "Starting opens the four-species choice with keyboard focus")
	var before_choice: String = JSON.stringify([app.game.party, app.game.rng.state, app.session_active])
	await key(KEY_ESCAPE)
	expect(app.screens.top() == "menu" and JSON.stringify([app.game.party, app.game.rng.state, app.session_active]) == before_choice, "Canceling starter selection leaves individuals, run and RNG untouched")
	await key(KEY_ENTER)
	await key(KEY_ENTER)
	await process_frame
	expect(app.screens.top() == "battle" and app.game.hand.size() == 6, "Keyboard chooses one starter and begins a six-card practice battle")
	var id: int = app.registry["hand.0"].get_instance_id()
	await key(KEY_1)
	await key(KEY_2)
	expect(app.game.selected.size() == 2 and app.registry["hand.0"].get_instance_id() == id, "Selection preserves the card node and focus infrastructure")
	expect(app.command_strip.visible and app.command_buttons[0].text.contains("→") and app.energy_label.text.contains("no plano"), "Visible command strip names the target and distinguishes planned from free actions")
	var plan_before: String = JSON.stringify([app.game.party, app.game.hand, app.game.rng.state, app.game.actions])
	await pad(JOY_BUTTON_LEFT_SHOULDER)
	expect(app.screens.top() == "plan" and focus_key().begins_with("plan."), "Controller LB opens the player command editor with modal focus")
	app.registry["plan.inspect.0"].grab_focus()
	await pad(JOY_BUTTON_A)
	expect(app.screens.top() == "inspect" and app.inspection.card.instance_id == app.game.hand[0].instance_id, "Plan has a touch-reachable power inspection without relying on hover or a keyboard")
	await pad(JOY_BUTTON_B)
	expect(app.screens.top() == "plan" and app.game.selected.size() == 2, "Returning from power details preserves the plan")
	app.registry["plan.remove.power.0"].grab_focus()
	await pad(JOY_BUTTON_A)
	expect(app.game.selected == [1] and app.screens.top() == "plan", "A plan command can be removed using controller focus")
	await pad(JOY_BUTTON_B)
	await key(KEY_1)
	expect(app.game.selected.size() == 2 and JSON.stringify([app.game.party, app.game.hand, app.game.rng.state, app.game.actions]) == plan_before, "Editing and restoring the plan preserves bodies, physical cards, RNG and round")
	await key(KEY_C)
	expect(app.screens.top() == "inspect", "Inspection is accessible without the mouse")
	expect(app.modal_root.z_index > 6, "Modal renders above lifted cards")
	await key(KEY_ESCAPE)
	expect(app.screens.top() == "battle", "Back from inspection preserves combat")
	await key(KEY_ESCAPE)
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	expect(app.screens.entries == ["battle", "pause", "settings"], "Nested options retain pause and combat")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	expect(app.screens.top() == "battle" and app.game.selected.size() == 2, "Resuming keeps the selected powers")
	var committed_hand: Array = app.cards.map(func(card): return card.card.instance_id)
	var committed_selection: Array = app.cards.map(func(card): return card.chosen)
	await pad(JOY_BUTTON_X)
	expect(app.busy and app.cards.map(func(card): return card.card.instance_id) == committed_hand and app.cards.map(func(card): return card.chosen) == committed_selection, "The committed hand and chosen powers stay visible during the speed queue")
	await key(KEY_C)
	expect(app.screens.top() == "battle", "Inspection cannot expose advanced-model HP during feedback")
	await pad(JOY_BUTTON_X)
	expect(app.game.actions == 1, "Repeated cast during feedback cannot spend another round")
	await create_timer(0.25).timeout
	expect(not app.busy and app.game.phase == "battle", "Feedback completes and releases input")
	expect(app.effects.trauma == 0 and app.effects.particles.is_empty(), "Reduced-motion casting has no shake or particles")
	expect(app.audio.voices.size() == 4, "Repeated feedback uses a bounded audio pool")
	var before_history: String = JSON.stringify([app.game.party, app.game.hand, app.game.rng.state, app.game.round_number])
	app.registry["hud.history"].grab_focus()
	await key(KEY_ENTER)
	expect(app.screens.top() == "history" and focus_key() == "history.back", "Last-round history is reachable with a focused back action")
	var history_text: String = ""
	for node in app.modal_root.find_children("*", "Label", true, false): history_text += node.text + "\n"
	expect(history_text.contains("HP retirado") and history_text.contains("Clareira 1") and not history_text.contains("target_slot"), "History describes actual HP and the original encounter without exposing internal targeting fields")
	await key(KEY_ESCAPE)
	expect(JSON.stringify([app.game.party, app.game.hand, app.game.rng.state, app.game.round_number]) == before_history, "Reviewing the last round does not replan enemies, advance combat or consume RNG")
	# Multiple living opponents exercise target cycling and invalid-side clicks.
	app.game.enemies[0].slot = 0
	var rival: Dictionary = app.game.enemies[0].duplicate(true)
	rival.uid = 999
	rival.slot = 2
	app.game.enemies.append(rival)
	app.game.hand = [app.game.party[0].cards[0].duplicate(true)]
	app.game.hand[0].target_slot = 0
	app.game.selected.assign([0])
	app.targeting_index = 0
	app._sync_battle()
	await key(KEY_E)
	expect(app.game.hand[0].target_slot == 2 and app.enemy_actors[2].targeted, "Target shortcut skips vacant slots and updates the visible target marker")
	await key(KEY_Q)
	expect(app.game.hand[0].target_slot == 0, "Reverse target cycling restores the original semantic slot")
	await key(KEY_P)
	app.registry["plan.target.0"].grab_focus()
	await key(KEY_ENTER)
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	expect(app.game.hand[0].target_slot == 2, "Popup keyboard navigation starts at the selected target and accepts the next occupied slot")
	await key(KEY_ESCAPE)
	await key(KEY_Q)
	var plan_view = load("res://scripts/ui/battle_plan.gd")
	var incomplete: Array = [{"kind": "power", "card": {"power": "rain_sweep"}, "priority": 0, "speed": 20}, {"kind": "power", "card": {"power": "lightning", "target_slot": 2}, "priority": 0, "speed": 18}]
	expect(plan_view.combo_notes(incomplete, [rival]).is_empty(), "An invalid fixed-area command without an eligible target stays inspectable without a phantom combo or crash")
	var planting: Array = [{"kind": "power", "card": {"power": "sowing", "target_slot": 2}, "priority": 0, "speed": 8}, {"kind": "power", "card": {"power": "fireball", "target_slot": 2}, "priority": 0, "speed": 14}]
	expect("\n".join(plan_view.combo_notes(planting, [rival])).contains("Fogo vem antes de Semeadura"), "Combo guidance warns when the triggering fire precedes seed preparation")
	planting[0].speed = 20
	expect("\n".join(plan_view.combo_notes(planting, [rival])).contains("semear antes de Fogo"), "Combo guidance identifies a compatible shared-target setup without guaranteeing future damage")
	planting[1].card.target_slot = 0
	expect(not "\n".join(plan_view.combo_notes(planting, [rival])).contains("Incêndio:"), "Different or vacant targets do not fabricate a seed-fire combination")
	var readout = load("res://scripts/ui/battle_readout.gd")
	expect(readout.event_line({"kind": "condition_spent", "actor_name": "Coruja", "condition": "charge"}).contains("Carga") and not readout.event_line({"kind": "condition_spent", "condition": "charge"}).contains("Eletrificado"), "History distinguishes spent Charge from offensive weakening")
	var saved_hand: Array = app.game.hand.duplicate(true)
	var saved_selection: Array = app.game.selected.duplicate()
	var saved_targeting: int = app.targeting_index
	var healer: Dictionary = app.game.make_umbral("dew", "vital", 77)
	healer.slot = 0
	app.game.party.append(healer)
	app.game.hand = [healer.cards[4].duplicate(true)]
	app.game.hand[0].target_slot = 0
	app.game.selected.clear()
	app.targeting_index = -1
	app._sync_battle()
	await key(KEY_1)
	app._click_slot("enemy", 2)
	expect(app.game.hand[0].target_slot == 0 and app.notice_label.text.contains("aliados"), "Healing rejects an enemy click without silently changing its allied target")
	app._click_slot("ally", 1)
	expect(app.game.hand[0].target_slot == 1, "Healing can target a different ally through the same visible slot interaction")
	app.game.party.pop_back()
	app.game.hand = saved_hand
	app.game.selected.assign(saved_selection)
	app.targeting_index = saved_targeting
	app._sync_battle()
	var node_id: int = app.cards[0].get_instance_id()
	app._click_slot("ally", 1)
	expect(app.screens.top() == "battle" and app.game.hand[0].target_slot == 0 and app.notice_label.text.contains("inimigos"), "An invalid-side target explains the error without opening an unrelated inspector")
	expect(app.cards[0].get_instance_id() == node_id, "Target editing retains the actual card node")
	await key(KEY_BACKSPACE)
	expect(app.game.selected.is_empty() and app.targeting_index == -1, "Clear shortcut leaves no stale aiming state")
	app.registry["hud.discard"].grab_focus()
	await key(KEY_ENTER)
	expect(app.screens.top() == "pile" and focus_key() == "pile.back", "Discard inspection is available by keyboard with a working back path")
	await key(KEY_ESCAPE)
	# KO cards remain in hand; keyboard focus must move to an actionable card.
	var companion: Dictionary = app.game.make_umbral("moss", "resilient", 2)
	companion.slot = 0
	app.game.party.append(companion)
	app.game.party[0].hp = 0
	app.game.hand = [app.game.party[0].cards[0].duplicate(true), companion.cards[2].duplicate(true)]
	app.game.hand[0].target_slot = 1
	app.game.hand[1].target_slot = 0
	app.game.selected.clear()
	app._sync_battle()
	app._focus("hand.0", "battle")
	expect(focus_key() == "hand.1", "A blocked first card cannot strand keyboard focus after nocaute")
	expect(app.cards[0].blocked_caption == "INCAPACITADO" and not app.cards[1].blocked, "Only incapacitated owners receive the nocaute label")
	companion.can_act_round = app.game.round_number + 1
	app._sync_battle()
	expect(app.cards[1].blocked and app.cards[1].blocked_caption == "PRÓXIMA RODADA", "Waiting after revive is distinguished from incapacitation")
	var old_battle: int = app.battle_root.get_instance_id()
	app.busy = true
	app.preferences.set_value("large_text", true)
	expect(app.battle_root.get_instance_id() == old_battle and not is_equal_approx(app.header_text_scale, app.preferences.text_scale()), "Large-text rebuilding is deferred while the committed event stream is visible")
	app.busy = false
	app._sync_text_scale()
	expect(app.battle_root.get_instance_id() != old_battle and is_equal_approx(app.header_text_scale, app.preferences.text_scale()), "Deferred text scale applies as soon as feedback releases the battle")
	# Inspect only the public enemy view: full exposes authored effects, restricted modes do not.
	var shown_enemy: Dictionary = app.game.enemies[0]
	var intent: Dictionary = {"actor_uid": int(shown_enemy.uid), "actor_slot": int(shown_enemy.slot), "category": "attack", "nature": "lightning", "conditions": {"electrified": 2}, "damage": 4, "scope": "single", "target_slot": 1}
	app.game.enemy_plan = [intent]
	for mode in ["full", "partial", "hidden"]:
		app.game.information_mode = mode
		app.inspection = {"umbral": app._public_individual(shown_enemy), "enemy": true}
		app._push("inspect")
		await process_frame
		var paragraphs: String = ""
		for node in app.modal_root.find_children("*", "Label", true, false): paragraphs += node.text + "\n"
		expect(paragraphs.contains("Natureza anunciada") == (mode == "full") and paragraphs.contains("Anuncia Eletrificado") == (mode == "full"), "Intent inspection obeys public nature/condition visibility: " + mode)
		app._pop()
	# Dense combat feedback stays inside the canvas and reserves space for its full motion.
	for reduced in [false, true]:
		app.effects.clear()
		app.effects.reduced_motion = reduced
		for i in range(24): app.effects.popup(Vector2(0, 0), ["BROTAÇÃO", "+6 ESCUDO", "+2 HP", "INCÊNDIO"][i % 4])
		var rectangles: Array[Rect2] = []
		for label in app.effects.popups:
			var rectangle: Rect2 = app.effects._popup_rect(label)
			expect(Rect2(Vector2.ZERO, app.effects.size).encloses(rectangle), "Normal/reduced-motion popup path stays inside the canvas")
			for previous in rectangles: expect(not rectangle.intersects(previous), "Dense damage, condition and support popup paths never overlap")
			rectangles.append(rectangle)
		expect(app.effects.popups.size() <= 18, "Readable popup layout preserves the bounded feedback pool")
	app.effects.clear()
	app.effects.reduced_motion = app.preferences.values.reduced_motion
	# Explicit capture destination can be canceled, then confirmed into a free slot.
	app.game.new_run(42013)
	app.game.phase = "reward"
	app.game._prepare_rewards()
	app._sync_battle()
	app._sync_phase()
	var before_capture: String = JSON.stringify([app.game.party, app.game.reward_offers, app.game.rng.state])
	app.registry["reward.0"].grab_focus()
	await key(KEY_ENTER)
	expect(app.screens.top() == "capture_destination" and app.capture_slot == 0 and app.registry["capture.slot.1"].disabled, "Capture suggests a genuinely free field slot and keeps the occupied slot unavailable")
	await key(KEY_ESCAPE)
	expect(app.screens.top() == "reward" and JSON.stringify([app.game.party, app.game.reward_offers, app.game.rng.state]) == before_capture, "Canceling capture preserves the rolled individual, offers and RNG")
	app.registry["reward.0"].grab_focus()
	await key(KEY_ENTER)
	app.registry["capture.confirm"].grab_focus()
	await key(KEY_ENTER)
	expect(app.screens.top() == "battle" and app.game.party.size() == 2 and app.game.party[1].slot == 0, "Confirming capture sends the individual directly to the selected free field slot")
	expect(app.game.round_number == 1 and app.game.actions == 0, "Capture destination does not spend a battle turn or action")
	await key(KEY_1)
	await key(KEY_P)
	app.registry["plan.cast"].grab_focus()
	await key(KEY_ENTER)
	expect(app.busy and app.phase_label.text.begins_with("EXECUTANDO"), "A valid plan can be committed directly from its editor, with a distinct execution phase")
	await create_timer(0.6).timeout
	expect(not app.busy and not app.command_strip.visible, "Resolved commands leave the strip before the next plan")
	# Six-member flows use real controls and scroll/focus, including large text.
	app.game.new_run(42013)
	for uid in range(2, 7):
		app.game.party.append(app.game.make_umbral(["moss", "volt", "dew"][(uid - 2) % 3], "resilient", uid))
	app.game.next_uid = 7
	app.game.start_encounter()
	app.game.phase = "reward"
	app.game._prepare_rewards()
	app._sync_battle()
	app._sync_phase()
	app.registry["reward.6"].grab_focus()
	await process_frame
	await process_frame
	expect(Rect2(Vector2.ZERO, app.size).has_point(app.registry["reward.6"].get_global_rect().get_center()), "Focus scrolls to the seventh reward in a six-member roster instead of clipping its button")
	app.registry["reward.0"].grab_focus()
	await key(KEY_ENTER)
	expect(app.screens.top() == "replacement", "Capturing with six members asks for an explicit outgoing individual")
	app.registry["replace.5"].grab_focus()
	await process_frame
	await process_frame
	expect(Rect2(Vector2.ZERO, app.size).has_point(app.registry["replace.5"].get_global_rect().get_center()) and Rect2(Vector2.ZERO, app.size).has_point(app.registry["replacement.back"].get_global_rect().get_center()), "Six-member release grid keeps the last choice and cancel reachable with large text")
	await key(KEY_ENTER)
	expect(app.screens.top() == "capture_destination" and app.game.party.size() == 6 and not app.game.umbral_by_uid(6).is_empty(), "Choosing an outgoing identity still preserves the full roster until destination confirmation")
	app.registry["capture.confirm"].grab_focus()
	await key(KEY_ENTER)
	expect(app.screens.top() == "battle" and app.game.party.size() == 6 and app.game.umbral_by_uid(6).is_empty() and not app.game.umbral_by_uid(7).is_empty(), "Release confirmation replaces precisely the chosen identity")
	app.game.party[0].hp -= 10
	app.game.party[1].hp -= 10
	app.game.umbral_by_uid(7).hp = 0
	app.game._sync_owner_zones()
	app.game.queue_item("potion", int(app.game.party[0].uid))
	app.game.queue_item("potion", int(app.game.party[1].uid))
	app.game.queue_item("revive", 7)
	app._sync_battle()
	app.registry["hud.backpack"].grab_focus()
	await key(KEY_ENTER)
	app.registry["pouch.cancel.2"].grab_focus()
	await process_frame
	await process_frame
	expect(Rect2(Vector2.ZERO, app.size).has_point(app.registry["pouch.cancel.2"].get_global_rect().get_center()) and Rect2(Vector2.ZERO, app.size).has_point(app.registry["pouch.back"].get_global_rect().get_center()), "Six-member pouch with three queued items keeps the final cancel and fixed back action reachable")
	await key(KEY_ENTER)
	expect(app.game.queued_items.size() == 2 and app.game.inventory.revive == 1, "Canceling a scrolled item does not consume stock")
	await key(KEY_ESCAPE)
	app.game.clear_plan()
	app.game.party[0].hp = 0
	app.game.phase = "replacement"
	app._sync_battle()
	app._sync_phase()
	expect(app.screens.top() == "ko_replacement" and app.registry["ko.finish"].disabled, "KO replacement explains and blocks continuing with no living active")
	app.registry["ko.0.0"].grab_focus()
	await key(KEY_ENTER)
	expect(not app.registry["ko.finish"].disabled, "Choosing one reserve enables continuing without requiring three actives")
	app.registry["ko.finish"].grab_focus()
	await key(KEY_ENTER)
	expect(app.screens.top() == "battle" and app.game.active_party(true).size() == 1, "Free replacement resumes with the single chosen active")
	app.registry["reserve.0"].grab_focus()
	await key(KEY_ENTER)
	expect(not app.registry["swap.slot.1"].disabled, "A declined KO slot stays available in the ordinary reserve selector")
	app.registry["swap.slot.1"].grab_focus()
	await key(KEY_ENTER)
	expect(app.game.preview().valid and app.game.preview().actions == 1 and int(app.game.umbral_by_uid(1).hp) == 0, "The selector queues delayed replacement as one action and preserves the incapacitated body until commitment")
	await key(KEY_SPACE)
	await create_timer(0.6).timeout
	expect(not app.busy and app.game.active_party(true).size() == 2 and int(app.game.umbral_by_uid(1).slot) == -1, "Conjurar completes a delayed replacement without forcing a third active")
	# A finishing blow leaves no next hand; presentation must retain the old
	# cards without indexing into the empty model during the animation.
	var displayed_hand: Array = app.cards.map(func(card): return card.card.instance_id)
	app.busy = true
	app.game.hand.clear()
	app.game.phase = "reward"
	app._sync_selection()
	expect(app.cards.map(func(card): return card.card.instance_id) == displayed_hand and app.registry["hud.backpack"].disabled, "A finishing queue keeps its hand visible and blocks item planning before rewards")
	print(JSON.stringify({"suite": "ui_input_flow", "checks": checks, "failed": failed, "device_validation": "synthetic Godot keyboard/gamepad events"}))
	app.audio.shutdown()
	await create_timer(0.12).timeout
	root.remove_child(app)
	app.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)
