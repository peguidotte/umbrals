extends RefCounted
## Versioned complete gameplay checkpoint. Diagnostic snapshot() is deliberately separate.
const Models = preload("res://scripts/domain/models.gd")
const Catalog = preload("res://scripts/catalog/game_catalog.gd")
const Reader = preload("res://scripts/domain/snapshot_records.gd")
const Power = preload("res://scripts/catalog/power_definition.gd")
const VERSION = 1
const SCALARS = ["encounter", "max_hp", "player_hp", "enemy_hp", "enemy_block", "player_block", "plays", "discards", "phase", "next_uid", "total_damage", "actions"]

static func capture(game: RefCounted) -> Dictionary:
	var state: Dictionary = {}
	for field in SCALARS: state[field] = game.get(field)
	return {"schema_version": VERSION, "catalog_id": game.catalog.fingerprint(), "seed_value": str(game.seed_value), "rng_seed": str(game.rng.seed), "rng_state": str(game.rng.state), "state": state, "party": Models.records(game.party), "hand": Models.records(game.hand), "deck": Models.records(game.deck), "discard_pile": Models.records(game.discard_pile), "selected": game.selected.duplicate(), "offers": Models.records(game.reward_offers), "statuses": Models.records(game.statuses), "inventory": Models.records(game.inventory.items), "history": Models.records(game.history), "last_result": result_snapshot(game.last_result)}

static func result_snapshot(result: Models.ResolutionResult) -> Variant:
	if result == null: return null
	var data: Dictionary = result.to_dict()
	data["projection_state"] = result.state_after.to_dict() if result.state_after != null else null
	return data

static func decode(data: Variant, catalog: Catalog) -> Dictionary:
	var reader = Reader.new()
	if not data is Dictionary or data.get("schema_version") != VERSION or data.get("catalog_id") != catalog.fingerprint(): return {"ok": false, "errors": ["Snapshot version/catalog mismatch"]}
	for key in ["state", "party", "hand", "deck", "discard_pile", "selected", "offers", "statuses", "inventory", "history", "last_result", "seed_value", "rng_seed", "rng_state"]:
		if not data.has(key): return {"ok": false, "errors": ["Missing checkpoint field: " + key]}
	for key in ["seed_value", "rng_seed", "rng_state"]:
		if not data.get(key) is String or not data[key].is_valid_int() or str(int(data[key])) != data[key]: return {"ok": false, "errors": ["Invalid exact RNG integer"]}
	if not data.get("state") is Dictionary or not data.get("party") is Array or data.party.is_empty() or data.party.size() > 3: return {"ok": false, "errors": ["Invalid run state/party"]}
	var state: Dictionary = {}
	for field in SCALARS:
		var value: Variant = data.state.get(field)
		if field == "phase":
			if value not in ["battle", "reward", "victory", "defeat"]: reader.errors.append("Invalid phase")
		elif not reader.integer(value): reader.errors.append("Invalid scalar: " + field)
		state[field] = value if field == "phase" else int(value) if reader.integer(value) else 0
	if state.encounter >= catalog.encounters.size() or state.max_hp <= 0 or state.player_hp > state.max_hp or state.plays > 7 or state.discards > 2 or state.next_uid <= 0: reader.errors.append("Run scalar bounds")
	if not reader.errors.is_empty(): return {"ok": false, "errors": reader.errors}
	if state.enemy_hp > catalog.encounters[state.encounter].hp: reader.errors.append("Enemy health exceeds definition")
	var party: Array[Models.Individual] = []
	var owners: Dictionary = {}
	for entry in data.party:
		var individual = reader.individual(entry, catalog)
		if individual == null or owners.has(individual.uid) or individual.uid >= state.next_uid: reader.errors.append("Invalid/duplicate individual UID")
		else:
			owners[individual.uid] = individual
			party.append(individual)
	state["party"] = party
	var seen: Dictionary = {}
	for field in ["hand", "deck", "discard_pile"]: state[field] = reader.cards(data.get(field), owners, catalog, seen)
	var expected: int = 0
	for individual in party: expected += catalog.form(individual).powers.size() * catalog.form(individual).copies_per_power
	if seen.size() != expected: reader.errors.append("Power instance conservation")
	var selected: Array[int] = []
	if not data.get("selected") is Array: reader.errors.append("Invalid selection")
	else:
		for value in data.selected:
			if not reader.integer(value) or value >= state.hand.size() or int(value) in selected: reader.errors.append("Invalid selected index")
			else: selected.append(int(value))
	if selected.size() > 3: reader.errors.append("Too many selected powers")
	state["selected"] = selected
	state["reward_offers"] = offers(data.get("offers"), catalog, owners, state, reader)
	var statuses: Dictionary = status_definitions(catalog)
	state["statuses"] = reader.statuses(data.get("statuses"), statuses)
	state["inventory"] = reader.inventory(data.get("inventory"), catalog, owners)
	state["history"] = reader.events(data.get("history"), statuses)
	state["last_result"] = last_result(data.get("last_result"), statuses, reader)
	if state.phase == "battle" and (state.enemy_hp <= 0 or state.player_hp <= 0 or state.plays <= 0): reader.errors.append("Battle cannot be ended")
	if state.phase in ["reward", "victory"] and state.enemy_hp != 0: reader.errors.append("Reward/victory requires defeated enemy")
	if state.phase == "victory" and state.encounter != catalog.encounters.size() - 1: reader.errors.append("Invalid victory encounter")
	if state.phase == "defeat" and state.player_hp > 0 and state.plays > 0: reader.errors.append("Invalid defeat")
	return {"ok": reader.errors.is_empty(), "errors": reader.errors, "state": state, "seed_value": int(data.seed_value), "rng_seed": int(data.rng_seed), "rng_state": int(data.rng_state)}

static func offers(data: Variant, catalog: Catalog, owners: Dictionary, state: Dictionary, reader: Reader) -> Array[Models.RewardOffer]:
	var result: Array[Models.RewardOffer] = []
	if not data is Array:
		reader.errors.append("Invalid reward offers")
		return result
	if (state.phase == "reward") == data.is_empty(): reader.errors.append("Reward phase/offer mismatch")
	var seen: Dictionary = {}
	for entry in data:
		if not entry is Dictionary:
			reader.errors.append("Invalid offer")
			continue
		if entry.get("kind") == "capture":
			var captured = reader.individual(entry.get("umbral"), catalog)
			if captured == null or captured.uid != state.next_uid or seen.has("capture"): reader.errors.append("Invalid captured UID")
			else:
				seen["capture"] = true
				result.append(Models.RewardOffer.new("capture", captured))
		elif entry.get("kind") == "evolve" and reader.integer(entry.get("uid"), 1) and owners.has(int(entry.uid)):
			var owner: Models.Individual = owners[int(entry.uid)]
			var edge = catalog.form(owner).transition(entry.get("transition_id", ""))
			var key: String = "%d:%s" % [owner.uid, entry.get("transition_id", "")]
			if edge == null or seen.has(key) or entry.get("source_form_id") != owner.form_id or entry.get("target_form_id") != edge.target_form_id or not edge.eligible(state.encounter, state.player_hp, owner.passive): reader.errors.append("Invalid evolution edge")
			else:
				seen[key] = true
				result.append(Models.RewardOffer.new("evolve", null, owner.uid, edge.target_form_id, owner.form_id, edge.transition_id))
		else: reader.errors.append("Unknown reward")
	if state.phase == "reward" and not seen.has("capture"): reader.errors.append("Missing capture offer")
	return result

static func status_definitions(catalog: Catalog) -> Dictionary:
	var result: Dictionary = {"burn": Power.BURN}
	var effects: Array = []
	for species in catalog.species.values():
		for shape in species.forms:
			for power in shape.powers: effects.append_array(power.effects)
	for encounter in catalog.encounters:
		for action in encounter.enemy.actions: effects.append_array(action.effects)
	for item in catalog.items: effects.append_array(item.effects)
	for effect in effects:
		if effect.status != null: result[effect.status.status_id] = effect.status
	return result

static func last_result(data: Variant, statuses: Dictionary, reader: Reader) -> Models.ResolutionResult:
	if data == null: return null
	if not data is Dictionary:
		reader.errors.append("Invalid last resolution")
		return null
	var result = Models.ResolutionResult.new()
	var score = Models.CastEvaluation.new()
	for field in ["energy", "damage", "direct_damage", "burn_added", "burn_tick", "block", "heal"]:
		if not reader.integer(data.get(field)): reader.errors.append("Invalid cast field: " + field)
		else: score.set(field, int(data[field]))
	for field in ["name", "reason"]:
		if not reader.string(data.get(field), 1000): reader.errors.append("Invalid cast text")
		else: score.set(field, data[field])
	if not data.get("valid") is bool or not data.get("ok") is bool: reader.errors.append("Invalid result flags")
	else:
		score.valid = data.valid
		result.ok = data.ok
	result.evaluation = score
	if data.get("projection_state") != null:
		result.state_after = reader.combat_state(data.projection_state, statuses)
	elif not data.has("projection_state"): reader.errors.append("Missing last projected state")
	for field in ["bonuses", "events"]:
		if not data.get(field) is Array: reader.errors.append("Invalid cast labels")
		else:
			for label in data[field]:
				if not reader.string(label, 1000): reader.errors.append("Invalid label")
				else: score.get(field).append(label)
	for field in ["incoming", "applied_damage", "effective_heal", "player_hp_after", "enemy_hp_after", "burn_after", "plays_after", "extra_draw"]:
		if not reader.integer(data.get(field)): reader.errors.append("Invalid resolution amount")
		else: result.set(field, int(data[field]))
	if data.get("phase") not in ["battle", "reward", "victory", "defeat"]: reader.errors.append("Invalid resolution phase")
	else: result.phase = data.phase
	result.reason = data.get("reason", "")
	result.combat_events = reader.events(data.get("combat_events"), statuses)
	return result
