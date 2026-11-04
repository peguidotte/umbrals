extends RefCounted
## Owns the current inspection and pile selection, translating battle gestures
## into navigation or rule targeting while exposing only public enemy details.
signal screen_requested(screen: String)
signal screen_pop_requested
signal cast_requested
signal selection_refresh_requested
signal notice_requested(text: String)
signal sound_requested(sound: String, quiet: bool)

const Content = preload("res://scripts/content.gd")
const BrowserBridge = preload("res://scripts/ui/browser_bridge.gd")
const Actor = preload("res://scripts/ui/actor.gd")
const PowerCard = preload("res://scripts/ui/power_card.gd")

var game: RefCounted
var turn: RefCounted
var screens: RefCounted
var inspection: Dictionary = {}
var pile_zone: String = "draw"

func configure(next_game: RefCounted, battle_turn: RefCounted, screen_stack: RefCounted) -> void:
	game = next_game
	turn = battle_turn
	screens = screen_stack

func click_slot(side: String, slot: int) -> void:
	if turn.busy or screens.top() != "battle": return
	if turn.targeting_index in game.selected and turn.targeting_index >= 0:
		var power: Dictionary = Content.POWERS[game.hand[turn.targeting_index].power]
		var expected: String = "enemy" if str(power.get("target", "enemy")) == "enemy" else "ally"
		if side == expected and game.set_target(turn.targeting_index, slot):
			sound_requested.emit("select", true)
			selection_refresh_requested.emit()
			return
		notice_requested.emit("Este poder só alcança " + ("inimigos aptos." if expected == "enemy" else "o próprio dono." if power.get("target", "enemy") == "self" else "aliados aptos."))
		sound_requested.emit("hover", true)
		return
	var individual: Dictionary = _at_slot(side, slot)
	if not individual.is_empty():
		inspection = {"umbral": BrowserBridge.public_individual(individual), "enemy": side == "enemy"}
		screen_requested.emit("inspect")

func inspect_actor(index: int) -> void:
	var individual: Dictionary = _at_slot("ally", index)
	if individual.is_empty(): return
	inspection = {"umbral": individual.duplicate(true)}
	screen_requested.emit("inspect")

func inspect_focused(focused: Control) -> void:
	if turn.busy: return
	if focused is PowerCard:
		inspection = {"umbral": focused.individual.duplicate(true), "card": focused.card.duplicate(true)}
	elif focused is Actor:
		if focused.identity.is_empty(): return
		inspection = {"umbral": BrowserBridge.public_individual(focused.identity), "enemy": focused.enemy}
	elif is_instance_valid(focused) and str(focused.get_meta("ui_id", "")).begins_with("reserve."):
		var index: int = int(str(focused.get_meta("ui_id")).get_slice(".", 1))
		var reserves: Array = game.reserves()
		if index >= reserves.size(): return
		inspection = {"umbral": reserves[index].duplicate(true)}
	elif turn.last_card_index >= 0 and turn.last_card_index < game.hand.size():
		var card: Dictionary = game.hand[turn.last_card_index]
		inspection = {"umbral": game.umbral_by_uid(int(card.owner)).duplicate(true), "card": card.duplicate(true)}
	else: return
	screen_requested.emit("inspect")

func open_pile(zone: String) -> void:
	if turn.busy or screens.top() != "battle": return
	pile_zone = zone
	screen_requested.emit("pile")

func open_plan() -> void:
	if turn.busy or screens.top() != "battle" or game.phase != "battle": return
	screen_requested.emit("plan")

func cast_from_plan() -> void:
	if turn.busy or screens.top() != "plan" or not game.preview().valid: return
	screen_pop_requested.emit()
	cast_requested.emit()

func inspect_plan_power(index: int) -> void:
	if turn.busy or index < 0 or index >= game.hand.size(): return
	var card: Dictionary = game.hand[index]
	inspection = {"umbral": game.umbral_by_uid(int(card.owner)).duplicate(true), "card": card.duplicate(true)}
	screen_requested.emit("inspect")

func open_history() -> void:
	if turn.busy or game.last_result.is_empty(): return
	screen_requested.emit("history")

func _at_slot(side: String, slot: int) -> Dictionary:
	for individual in game.party if side == "ally" else game.enemies:
		if int(individual.get("slot", -1)) == slot: return individual
	return {}
