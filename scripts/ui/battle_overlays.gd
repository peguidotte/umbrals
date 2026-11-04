extends RefCounted
## Builds battle overlays from read-only game queries and the current UI draft.
## All decisions are returned as semantic intents to the session controller.
signal control_created(control: Control, key: String, screen: String)
signal back_requested
signal remove_requested(kind: String, id: int)
signal target_requested(index: int, slot: int)
signal inspect_requested(index: int)
signal clear_requested
signal cast_requested
signal swap_requested(slot: int)
signal swap_cancel_requested(slot: int)
signal formation_requested(slot: int, uid: int)
signal formation_confirmed
signal item_requested(item: String, uid: int)
signal item_cancel_requested(index: int)
signal ko_requested(slot: int, uid: int)
signal ko_finished
signal reward_requested(index: int)
signal open_formation_requested
signal history_requested
signal replacement_requested(index: int, uid: int)
signal capture_slot_requested(slot: int)
signal confirm_reward_requested(index: int, uid: int, slot: int)

const Rules = preload("res://scripts/rules.gd")
const Content = preload("res://scripts/content.gd")
const ItemPresentation = preload("res://scripts/ui/item_presentation.gd")
const BrowserBridge = preload("res://scripts/ui/browser_bridge.gd")
const BattleReviewScreen = preload("res://scripts/ui/battle_review_screen.gd")
const BattlePlanScreen = preload("res://scripts/ui/battle_plan_screen.gd")
const BattleDialogScreen = preload("res://scripts/ui/battle_dialog_screen.gd")
const RewardScreen = preload("res://scripts/ui/reward_screen.gd")
var active_view: RefCounted

func build(screen: String, ui: RefCounted, viewport_size: Vector2, game: RefCounted, preferences: RefCounted, draft: Dictionary) -> Control:
	match screen:
		"inspect":
			var selected: Dictionary = draft.inspection
			var power: Dictionary = {}
			if selected.has("card"): power = Rules.power_effect(selected.card, selected.umbral, game.active_party(true).size())
			return _review().inspection(ui, viewport_size, selected, game.party, game.enemies, game.public_intents(), power)
		"pile":
			var zone: String = draft.pile_zone
			var source: Array = game.deck if zone == "draw" else game.discard_pile
			return _review().pile(ui, viewport_size, zone, source, game.party)
		"history": return _review().history(ui, viewport_size, game.last_result)
		"plan":
			var view = _plan()
			return view.build(ui, viewport_size, game.preview(), game.action_budget(), game.planned_actions(), game.hand, game.party.map(BrowserBridge.public_individual), game.enemies.map(BrowserBridge.public_individual), preferences.text_scale())
		"swap":
			var uid: int = int(draft.reserve_uid)
			var occupants: Dictionary = _occupants(game.party)
			var reasons: Dictionary = {}
			for slot in range(3): reasons[slot] = game.swap_reason(slot, uid)
			return _dialogs().swap(ui, viewport_size, game.umbral_by_uid(uid), occupants, reasons, game.queued_swaps)
		"formation": return _dialogs().formation(ui, viewport_size, game.party, draft.formation_draft)
		"pouch":
			var reasons: Dictionary = {}
			for individual in game.party:
				for item in ItemPresentation.choices(Content.CONSUMABLES, game.inventory):
					reasons["%s:%d" % [item, int(individual.uid)]] = game.item_reason(item, int(individual.uid))
			return _dialogs().pouch(ui, viewport_size, game.inventory, game.party, reasons, game.queued_items, Content.CONSUMABLES)
		"ko_replacement": return _dialogs().ko(ui, viewport_size, _occupants(game.party), game.reserves(), game.active_party(true).size())
		"reward": return _rewards().rewards(ui, viewport_size, game.reward_offers, game.party)
		"replacement":
			var index: int = int(draft.replacement_index)
			return _rewards().replacement(ui, viewport_size, game.reward_offers[index], game.party, index)
		"capture_destination":
			var index: int = int(draft.capture_index)
			var uid: int = int(draft.capture_replace_uid)
			return _rewards().destination(ui, viewport_size, game.reward_offers[index], game.capture_destinations(index, uid), _occupants(game.party), game.umbral_by_uid(uid), index, uid, int(draft.capture_slot))
	return null

func _occupants(party: Array) -> Dictionary:
	var occupants: Dictionary = {}
	for slot in range(Rules.MAX_ACTIVE):
		occupants[slot] = {}
		for individual in party:
			if int(individual.get("slot", -1)) == slot:
				occupants[slot] = individual
				break
	return occupants

func _review() -> RefCounted:
	var view = BattleReviewScreen.new()
	active_view = view
	view.back_requested.connect(back_requested.emit)
	view.control_created.connect(control_created.emit)
	return view

func _plan() -> RefCounted:
	var view = BattlePlanScreen.new()
	active_view = view
	view.control_created.connect(func(control: Control, key: String): control_created.emit(control, key, "plan"))
	view.remove_requested.connect(remove_requested.emit)
	view.target_requested.connect(target_requested.emit)
	view.inspect_requested.connect(inspect_requested.emit)
	view.back_requested.connect(back_requested.emit)
	view.clear_requested.connect(clear_requested.emit)
	view.cast_requested.connect(cast_requested.emit)
	return view

func _dialogs() -> RefCounted:
	var view = BattleDialogScreen.new()
	active_view = view
	view.control_created.connect(control_created.emit)
	view.back_requested.connect(back_requested.emit)
	view.swap_requested.connect(swap_requested.emit)
	view.swap_cancel_requested.connect(swap_cancel_requested.emit)
	view.formation_requested.connect(formation_requested.emit)
	view.formation_confirmed.connect(formation_confirmed.emit)
	view.item_requested.connect(item_requested.emit)
	view.item_cancel_requested.connect(item_cancel_requested.emit)
	view.ko_requested.connect(ko_requested.emit)
	view.ko_finished.connect(ko_finished.emit)
	return view

func _rewards() -> RefCounted:
	var view = RewardScreen.new()
	active_view = view
	view.control_created.connect(control_created.emit)
	view.reward_requested.connect(reward_requested.emit)
	view.formation_requested.connect(open_formation_requested.emit)
	view.history_requested.connect(history_requested.emit)
	view.replacement_requested.connect(replacement_requested.emit)
	view.slot_requested.connect(capture_slot_requested.emit)
	view.confirm_requested.connect(confirm_reward_requested.emit)
	view.back_requested.connect(back_requested.emit)
	return view
