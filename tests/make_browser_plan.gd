extends SceneTree

const Rules = preload("res://scripts/rules.gd")

func over_budget(g: RefCounted) -> Array:
	for mask in range(1, 1 << g.hand.size()):
		var cards: Array = []
		var indices: Array = []
		for i in range(g.hand.size()):
			if mask & (1 << i):
				cards.append(g.hand[i])
				indices.append(i)
		if cards.size() > 3: continue
		var score: Dictionary = Rules.evaluate(cards, g.party, g.enemy_burn)
		if int(score.energy) > 3: return indices
	return []

func make_plan(replacement: bool = false) -> Dictionary:
	var game = Rules.new()
	game.new_run(42013)
	var plan: Array = []
	var steps: int = 0
	while game.phase not in ["victory", "defeat"] and steps < 30:
		if replacement and game.encounter == 2: break
		if game.phase == "reward":
			var index: int = 0 if game.encounter == 0 or replacement else 1
			var offer: Dictionary = game.reward_offers[index].duplicate(true)
			var replace_uid: int = int(game.party[1].uid) if replacement and game.party.size() == 3 else -1
			var step: Dictionary = {"action": "reward", "index": index, "count": game.reward_offers.size(), "offer": offer, "replace_uid": replace_uid}
			if not game.choose_reward(index, replace_uid):
				push_error("Plan selected an invalid reward")
				break
			step["party_after"] = game.party.duplicate(true)
			plan.append(step)
		else:
			game.selected = game.best_selection()
			var score: Dictionary = game.preview()
			var step: Dictionary = {"action": "play", "indices": game.selected.duplicate(), "hand": game.hand.duplicate(true), "damage": score.damage, "energy": score.energy, "illegal_indices": over_budget(game)}
			game.play()
			step["hp_after"] = game.player_hp
			step["phase_after"] = game.phase
			plan.append(step)
		steps += 1
	return {"seed": 42013, "outcome": game.phase, "plan": plan}

func _init() -> void:
	var primary: Dictionary = make_plan()
	var replacement: Dictionary = make_plan(true)
	var file = FileAccess.open("res://test-results/browser-plan.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"primary": primary, "replacement": replacement}))
	print("Browser plans: main=", primary.outcome, ", replacement=", replacement.outcome)
	quit(0 if primary.outcome == "victory" and replacement.outcome == "battle" else 1)
