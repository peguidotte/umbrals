extends SceneTree
const Rules = preload("res://scripts/rules.gd")
func _init() -> void:
	var reports: Array = []
	for policy in ["existing_heuristic", "deploy_captures", "random_legal"]:
		var cooperative: bool = policy != "existing_heuristic"
		var wins: int = 0
		var total_rounds: int = 0
		var incoming: int = 0
		var kos: int = 0
		for seed_number in range(100):
			var game = Rules.new()
			game.new_run(seed_number)
			var policy_rng = RandomNumberGenerator.new()
			policy_rng.seed = seed_number + 10000
			var steps: int = 0
			while game.phase not in ["victory", "defeat"] and steps < 100:
				if game.phase == "reward": game.choose_reward(0 if cooperative or game.encounter == 0 else 1)
				elif game.phase == "replacement":
					for companion in game.active_party():
						if int(companion.hp) == 0 and not game.reserves().is_empty(): game.replace_after_ko(int(companion.slot), int(game.reserves()[0].uid))
					game.finish_replacements()
				else:
					if cooperative and not game.reserves().is_empty() and game.active_party().size() < 3:
						for slot in range(3):
							if game._at_slot(game.party, slot).is_empty():
								game.queue_deploy(slot, int(game.reserves()[0].uid))
								break
					if policy == "random_legal":
						var legal: Array = []
						for mask in range(1, 1 << mini(game.hand.size(), 12)):
							var selection: Array[int] = []
							for i in range(mini(game.hand.size(), 12)):
								if mask & (1 << i): selection.append(i)
							game.selected = selection
							if game.preview().valid: legal.append(selection)
						game.selected.assign(legal[policy_rng.randi_range(0, legal.size() - 1)] if not legal.is_empty() else [])
					else: game.selected = game.best_selection()
					if game.preview().valid: game.play()
					else: game.redraw()
					incoming += int(game.last_result.get("incoming", 0))
					for event in game.last_result.get("events", []):
						if event.kind == "ko" and event.target_side == "ally": kos += 1
				steps += 1
			if game.phase == "victory": wins += 1
			total_rounds += game.actions
		reports.append({"policy": policy, "seeds": 100, "wins": wins, "mean_rounds": total_rounds / 100.0, "mean_incoming": incoming / 100.0, "kos": kos})
	print(JSON.stringify({"policies": reports, "limits": "Policies without consumables or manual target edits; random policy RNG is separate from gameplay. Not human difficulty/fun."}))
	quit()
