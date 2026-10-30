extends SceneTree
## Generate legal seeded actions from the production controller; browser input replays them.
const Expedition = preload("res://scripts/expedition/expedition.gd")

func make_plan(branch: String) -> Dictionary:
	var run = Expedition.new()
	run.new_run(42013, "partial", "ember")
	var game = run.battle
	var plan: Array = []
	var steps: int = 0
	while run.phase not in ["victory", "defeat"] and steps < 120:
		if run.phase == "map":
			var node: String = "clearing" if run.completed.is_empty() else (branch if run.completed.size() == 1 else "boss")
			if not run.choose_node(node):
				push_error("Cannot enter " + node)
				break
			plan.append({"action": "node", "id": node, "party_after": game.party.duplicate(true)})
		elif run.phase == "reward":
			var offer: Dictionary = game.reward_offers[0].duplicate(true)
			var destination: int = (0 if branch == "spring" else -1) if offer.kind == "capture" else -2
			if not run.choose_reward(0, -1, destination):
				push_error("Cannot choose reward")
				break
			plan.append({"action": "reward", "index": 0, "offer": offer, "capture_slot": destination, "party_after": game.party.duplicate(true)})
		elif game.phase == "replacement":
			var swaps: Array = []
			for unit in game.active_party():
				if int(unit.hp) == 0 and not game.reserves().is_empty():
					var uid: int = int(game.reserves()[0].uid)
					if game.replace_after_ko(int(unit.slot), uid): swaps.append({"slot": int(unit.slot), "in_uid": uid})
			if not game.finish_replacements():
				push_error("Cannot finish replacements")
				break
			plan.append({"action": "replacement", "swaps": swaps, "party_after": game.party.duplicate(true)})
		else:
			var swaps: Array = []
			if not game.reserves().is_empty() and game.active_party(true).size() < 3:
				var slot: int = 0
				while game.active_party(true).any(func(unit): return int(unit.slot) == slot): slot += 1
				var uid: int = int(game.reserves()[0].uid)
				if game.queue_deploy(slot, uid): swaps.append({"slot": slot, "in_uid": uid})
			game.selected = game.best_selection()
			var score: Dictionary = game.preview()
			var step: Dictionary = {"action": "play", "hand": game.hand.duplicate(true), "indices": game.selected.duplicate(), "swaps": swaps, "reroll": not score.valid}
			var result: Dictionary = game.play() if score.valid else {"ok": game.redraw()}
			if not result.ok:
				push_error("Cannot play planned turn")
				break
			step.party_after = game.party.duplicate(true)
			step.enemies_after = game.enemies.duplicate(true)
			step.phase_after = game.phase
			plan.append(step)
			run.settle_battle()
		steps += 1
	return {"seed": 42013, "branch": branch, "outcome": run.phase, "plan": plan}

func _init() -> void:
	var plans: Dictionary = {"thicket": make_plan("thicket"), "spring": make_plan("spring")}
	var file = FileAccess.open("res://test-results/expedition-plan.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(plans, "  "))
	file.close()
	print("Expedition plans: thicket=", plans.thicket.outcome, ", spring=", plans.spring.outcome)
	quit(0 if plans.thicket.outcome in ["victory", "defeat"] and plans.spring.outcome in ["victory", "defeat"] else 1)
