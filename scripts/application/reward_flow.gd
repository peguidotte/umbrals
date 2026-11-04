extends RefCounted
## Owns the pending capture choice and commits rewards through the active run.
## Presentation receives only semantic navigation and feedback events.
signal screen_requested(screen: String)
signal screen_reset_requested(screen: String)
signal screen_refresh_requested
signal battle_refresh_requested
signal focus_memory_requested(screen: String, key: String)
signal checkpoint_requested
signal sound_requested(sound: String)
signal reward_feedback_requested(individual: Dictionary, evolved: bool)
signal logged(event_name: String, details: Dictionary)
signal debug_requested

const Rules = preload("res://scripts/rules.gd")

var game: RefCounted
var session: RefCounted
var replacement_index: int = -1
var capture_index: int = -1
var capture_slot: int = -1
var capture_replace_uid: int = -1

func configure(next_game: RefCounted, run_session: RefCounted) -> void:
	game = next_game
	session = run_session

func take_reward(index: int) -> void:
	if game.reward_offers[index].kind == "capture":
		if game.party.size() >= Rules.MAX_TEAM:
			replacement_index = index
			screen_requested.emit("replacement")
		else:
			choose_capture_destination(index)
		return
	accept_reward(index)

func choose_capture_destination(index: int, outgoing_uid: int = -1) -> void:
	capture_index = index
	capture_replace_uid = outgoing_uid
	capture_slot = -1
	var outgoing: Dictionary = game.umbral_by_uid(outgoing_uid)
	if int(outgoing.get("slot", -1)) >= 0: capture_slot = int(outgoing.slot)
	else:
		for slot in game.capture_destinations(index, outgoing_uid):
			if slot >= 0:
				capture_slot = slot
				break
	screen_requested.emit("capture_destination")

func select_capture_slot(slot: int) -> void:
	if not slot in game.capture_destinations(capture_index, capture_replace_uid): return
	capture_slot = slot
	focus_memory_requested.emit("capture_destination", "capture.reserve" if slot < 0 else "capture.slot.%d" % slot)
	screen_refresh_requested.emit()

func accept_reward(index: int, replace_uid: int = -1, destination: int = -2) -> void:
	var offer: Dictionary = game.reward_offers[index].duplicate(true)
	var evolved: bool = offer.kind == "evolve"
	var accepted: bool = session.expedition.choose_reward(index, replace_uid, destination) if session.expedition_active else game.choose_reward(index, replace_uid, destination)
	if not accepted: return
	replacement_index = -1
	capture_index = -1
	capture_replace_uid = -1
	if session.expedition_active:
		checkpoint_requested.emit()
		screen_reset_requested.emit("map")
		sound_requested.emit("evolve" if evolved else "capture")
		logged.emit("reward_chosen", {"kind": offer.kind, "replacement": replace_uid, "party": game.party})
		return
	battle_refresh_requested.emit()
	screen_reset_requested.emit("battle")
	sound_requested.emit("evolve" if evolved else "capture")
	var individual: Dictionary = game.umbral_by_uid(int(offer.uid)) if evolved else offer.umbral
	reward_feedback_requested.emit(individual, evolved)
	logged.emit("reward_chosen", {"kind": offer.kind, "replacement": replace_uid, "party": game.party})
	debug_requested.emit()
