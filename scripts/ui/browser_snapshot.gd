extends RefCounted
## Projects public session data for browser automation. Enemy actions come only
## from Rules.public_intents(), and in-flight reactions remain hidden until done.
const Content = preload("res://scripts/content.gd")
const BrowserBridge = preload("res://scripts/ui/browser_bridge.gd")
const JourneyMenu = preload("res://scripts/ui/journey_menu.gd")

static func build(game: RefCounted, session: RefCounted, screens: RefCounted, preferences: RefCounted, presentation: Dictionary) -> Dictionary:
	var party_public: Array = []
	var enemies_public: Array = []
	for individual in game.party: party_public.append(BrowserBridge.public_individual(individual))
	for individual in game.enemies: enemies_public.append(BrowserBridge.public_individual(individual))
	var busy: bool = presentation.busy
	var session_active: bool = presentation.session_active
	var feedback: Dictionary = presentation.feedback.duplicate()
	feedback["rejected_busy_casts"] = presentation.rejected_busy_casts
	var state: Dictionary = {
		"version": Content.VERSION, "revision": presentation.revision,
		"screen": screens.top(), "stack": screens.entries, "busy": busy,
		"phase": game.phase if session_active else "menu",
		"hand": game.hand if session_active else [], "deck": game.deck, "discard": game.discard_pile,
		"party": party_public, "enemies": enemies_public, "selected": game.selected,
		"targeting_index": presentation.targeting_index, "planned_actions": game.planned_actions(),
		"hp": game.player_hp, "enemy_hp": game.enemy_hp, "plays": game.plays, "actions": game.actions,
		"encounter": game.encounter, "round_number": game.round_number,
		"action_budget": game.action_budget(), "hand_capacity": game.hand_capacity(),
		"queued_swaps": game.queued_swaps, "queued_items": game.queued_items, "inventory": game.inventory,
		"intents": game.public_intents(), "information_mode": game.information_mode,
		"pending_information_mode": game.pending_information_mode, "stats": session.stats,
		"offers": game.reward_offers, "preview": game.preview(), "preferences": preferences.values,
		"logical_size": presentation.logical_size, "device": presentation.device, "feedback": feedback,
		"expedition": session.expedition.public_state() if session.expedition_active else {},
		"checkpoint_status": session.run_save.last_status,
		"resolved_reactions": [] if busy else game.last_result.get("events", []).filter(func(event: Dictionary) -> bool: return event.kind == "reaction"),
		"overlay_z": presentation.overlay_z, "card_max_z": preload("res://scripts/ui/power_card.gd").RAISED_Z, "audio": presentation.audio,
		"node_count": presentation.node_count, "title_effect": presentation.title_effect,
		"title_audio": presentation.title_audio, "input_serial": presentation.input_serial,
		"interaction_serial": presentation.interaction_serial, "last_interaction": presentation.last_interaction,
	}
	if presentation.has("refuge"): state["refuge"] = presentation.refuge
	if presentation.has("journey_checkpoint"):
		var checkpoint: Dictionary = presentation.journey_checkpoint
		state["journey_summary"] = JourneyMenu.checkpoint_summary(checkpoint) if not checkpoint.is_empty() else ""
		state["journey_party"] = checkpoint.get("party", []).map(BrowserBridge.public_individual)
	return state
