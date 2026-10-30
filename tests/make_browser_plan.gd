extends SceneTree
## This read-only plan drives the same legal actions through real browser controls.
const Rules = preload("res://scripts/rules.gd")
const Content = preload("res://scripts/content.gd")

func over_budget(game: RefCounted) -> Array:
	for mask in range(1, 1 << game.hand.size()):
		var cards: Array = []
		var indices: Array = []
		for index in range(game.hand.size()):
			if mask & (1 << index):
				cards.append(game.hand[index])
				indices.append(index)
		var score: Dictionary = Rules.evaluate(cards, game.party)
		if int(score.actions) > 3: return indices
	return []

func make_plan(alternate: bool = false) -> Dictionary:
	var game = Rules.new()
	game.new_run(42013)
	var plan: Array = []
	var steps: int = 0
	var deployed_uids: Dictionary = {1: true}
	while game.phase not in ["victory", "defeat"] and steps < 100:
		if game.phase == "reward":
			var index: int = 0 if game.encounter == 0 or alternate else 1
			var offer: Dictionary = game.reward_offers[index].duplicate(true)
			var step: Dictionary = {"action": "reward", "index": index, "count": game.reward_offers.size(), "offer": offer, "replace_uid": -1}
			var destination: int = 0 if alternate and game.encounter == 0 else -1
			if offer.kind == "capture": step.capture_slot = destination
			if not game.choose_reward(index, -1, destination if offer.kind == "capture" else -2):
				push_error("Plan selected an invalid reward")
				break
			step["party_after"] = game.party.duplicate(true)
			plan.append(step)
		elif game.phase == "replacement":
			var swaps: Array = []
			var reserves: Array = game.reserves()
			if not reserves.is_empty():
				var destination: int = 1
				for companion in game.party:
					if int(companion.slot) >= 0 and int(companion.hp) == 0:
						destination = int(companion.slot)
						break
				var incoming: int = int(reserves[0].uid)
				if not game.replace_after_ko(destination, incoming):
					push_error("Plan selected an invalid KO replacement")
					break
				swaps.append({"slot": destination, "in_uid": incoming})
			if not game.finish_replacements():
				push_error("Plan could not finish KO replacements")
				break
			plan.append({"action": "ko_replacement", "swaps": swaps, "party_after": game.party.duplicate(true)})
		else:
			var swaps: Array = []
			if not game.reserves().is_empty() and game.active_party().size() < 3:
				var incoming: int = -1
				for reserve in game.reserves():
					if not deployed_uids.has(int(reserve.uid)):
						incoming = int(reserve.uid)
						break
				var destination: int = 0 if game.active_party().size() == 1 else 2
				if incoming > 0 and not game.queue_deploy(destination, incoming):
					push_error("Plan could not deploy the captured reserve")
					break
				if incoming > 0:
					swaps.append({"slot": destination, "in_uid": incoming})
					deployed_uids[incoming] = true
			game.selected = game.best_selection()
			# A legal deployment-only turn lets the browser inspect the full 3×3
			# formation before subsequent attacks knock out an opponent.
			if alternate and game.encounter == 2 and not swaps.is_empty():
				game.selected.clear()
			var score: Dictionary = game.preview()
			var step: Dictionary = {"action": "play", "indices": game.selected.duplicate(), "swaps": swaps, "hand": game.hand.duplicate(true), "damage": score.damage, "cost": score.actions, "illegal_indices": over_budget(game), "enemies_before": game.enemies.duplicate(true)}
			var result: Dictionary = game.play() if score.valid else {"ok": game.redraw()}
			if not result.ok:
				push_error("Plan selected an invalid conjuration")
				break
			step["reroll"] = not score.valid
			step["party_after"] = game.party.duplicate(true)
			step["enemies_after"] = game.enemies.duplicate(true)
			step["phase_after"] = game.phase
			plan.append(step)
		steps += 1
	return {"seed": 42013, "outcome": game.phase, "plan": plan}

func make_elemental_plan() -> Dictionary:
	var game = Rules.new()
	game.new_run(42013, "partial", "moss")
	var plan: Array = []
	var observed: Dictionary = {}
	var steps: int = 0
	while game.phase not in ["victory", "defeat"] and steps < 80:
		if game.phase == "reward":
			var offer: Dictionary = game.reward_offers[0].duplicate(true)
			game.choose_reward(0)
			plan.append({"action": "reward", "index": 0, "offer": offer, "party_after": game.party.duplicate(true)})
		elif game.phase == "replacement":
			var replacements: Array = []
			for unit in game.active_party():
				if int(unit.hp) == 0 and not game.reserves().is_empty():
					var uid: int = int(game.reserves()[0].uid)
					game.replace_after_ko(int(unit.slot), uid)
					replacements.append({"slot": int(unit.slot), "in_uid": uid})
			game.finish_replacements()
			plan.append({"action": "ko_replacement", "swaps": replacements, "party_after": game.party.duplicate(true)})
		else:
			var swaps: Array = []
			if not game.reserves().is_empty() and game.active_party(true).size() < 3:
				for slot in range(3):
					if game._at_slot(game.party, slot).is_empty():
						var uid: int = int(game.reserves()[0].uid)
						game.queue_deploy(slot, uid)
						swaps.append({"slot": slot, "in_uid": uid})
						break
			var desired: String = "sprouting" if game.encounter == 0 else "bloom" if game.encounter == 1 else "wildfire"
			var targets: Array = []
			if observed.has(desired):
				game.selected = game.best_selection()
			else:
				var target_slot: int = game._first_living_slot(game.enemies)
				if game.encounter == 2:
					# Work with the visible taunter instead of repeatedly aiming
					# through it. Prepare one seed, then wait for the fire hand.
					target_slot = 1 if int(game._at_slot(game.enemies, 1).hp) > 0 else game._first_living_slot(game.enemies)
				var seed_target: Dictionary = game._at_slot(game.enemies, target_slot)
				for index in range(game.hand.size()):
					var card: Dictionary = game.hand[index]
					var preferred: bool = card.power == "sowing" or card.power == "root_wall"
					if game.encounter == 1 and card.power == "tidal_splash": preferred = true
					if game.encounter == 2 and card.power == "fireball": preferred = true
					if game.encounter == 2:
						if card.power in ["flame_guard", "dew_mend"]: preferred = true
						if card.power == "fireball" and int(seed_target.get("statuses", {}).get("seed", 0)) == 0: preferred = false
						if card.power == "sowing" and game.selected.any(func(i: int) -> bool: return game.hand[i].power == "sowing"): preferred = false
					if game.encounter > 0 and card.power == "sowing" and int(seed_target.get("statuses", {}).get("seed", 0)) > 0: preferred = false
					if not preferred or not game.card_usable(index): continue
					if card.power != "root_wall":
						if seed_target.is_empty() or int(seed_target.hp) <= 0: continue
						if not game.set_target(index, target_slot): continue
						targets.append({"index": index, "slot": target_slot, "side": "enemy" if Content.POWERS[card.power].get("target", "enemy") == "enemy" else "ally"})
					game.selected.append(index)
					if not game.preview().valid: game.selected.erase(index)
				if game.selected.is_empty() and swaps.is_empty(): game.selected = game.best_selection()
			var score: Dictionary = game.preview()
			var step: Dictionary = {"action": "play", "indices": game.selected.duplicate(), "swaps": swaps, "targets": targets, "hand": game.hand.duplicate(true), "damage": score.damage, "cost": score.actions, "illegal_indices": [], "enemies_before": game.enemies.duplicate(true)}
			var result: Dictionary = game.play() if score.valid else {"ok": game.redraw()}
			for event in game.last_result.events:
				if event.kind == "reaction": observed[event.reaction] = true
			step.merge({"reroll": not score.valid, "party_after": game.party.duplicate(true), "enemies_after": game.enemies.duplicate(true), "phase_after": game.phase})
			plan.append(step)
		steps += 1
	return {"seed": 42013, "starter": "moss", "outcome": game.phase, "plan": plan, "reactions": observed.keys()}

func make_electric_plan() -> Dictionary:
	var game = Rules.new()
	game.new_run(42013, "partial", "volt")
	var plan: Array = []
	var control_seen: bool = false
	var conduction_seen: bool = false
	for step_number in range(40):
		if game.phase in ["defeat", "victory"] or conduction_seen: break
		if game.phase == "reward":
			var offer: Dictionary = game.reward_offers[0].duplicate(true)
			game.choose_reward(0)
			plan.append({"action": "reward", "index": 0, "offer": offer, "party_after": game.party.duplicate(true)})
			continue
		var swaps: Array = []
		if not game.reserves().is_empty() and game.active_party().size() < 2:
			game.queue_deploy(0, int(game.reserves()[0].uid))
			swaps.append({"slot": 0, "in_uid": int(game.reserves()[0].uid)})
		game.selected = game.best_selection()
		if not control_seen:
			game.selected.clear()
			for index in range(game.hand.size()):
				if game.hand[index].power == "interference":
					game.selected.append(index)
					break
		var score: Dictionary = game.preview()
		var step: Dictionary = {"action": "play", "indices": game.selected.duplicate(), "swaps": swaps, "hand": game.hand.duplicate(true), "damage": score.damage, "cost": score.actions, "illegal_indices": [], "enemies_before": game.enemies.duplicate(true)}
		game.play()
		for event in game.last_result.events:
			if event.kind == "condition" and event.get("condition", "") == "electrified": control_seen = true
			if event.get("reaction", "") == "conduction": conduction_seen = true
		step.merge({"party_after": game.party.duplicate(true), "enemies_after": game.enemies.duplicate(true), "phase_after": game.phase})
		plan.append(step)
	return {"seed": 42013, "starter": "volt", "outcome": game.phase, "plan": plan, "control_seen": control_seen, "conduction_seen": conduction_seen}

func _init() -> void:
	var primary: Dictionary = make_plan()
	var alternate: Dictionary = make_plan(true)
	var elemental: Dictionary = make_elemental_plan()
	var electric: Dictionary = make_electric_plan()
	var file = FileAccess.open("res://test-results/browser-plan.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"primary": primary, "replacement": alternate, "elemental": elemental, "electric": electric, "coverage": {"full_roster_release": "numerical fixture; six roster members cannot be captured in three encounters"}}))
	print("Browser plans: main=", primary.outcome, ", alternate=", alternate.outcome, ", elemental=", elemental.outcome, " ", elemental.reactions, ", electric=", electric.control_seen, "/", electric.conduction_seen)
	quit(0 if primary.outcome == "victory" and alternate.outcome in ["victory", "defeat"] and electric.control_seen and electric.conduction_seen and ["sprouting", "bloom", "wildfire"].all(func(id: String) -> bool: return id in elemental.reactions) else 1)
