extends RefCounted
## Private validated expeditions exercise production swap/damage/revive commands.
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Rules = preload("res://scripts/rules.gd")

static func fixture(kind: String) -> Dictionary:
	for seed: int in range(42013,42045):
		var run = Expedition.new()
		run.new_run(seed,"full","moss")
		var game: RefCounted = run.battle
		game.party[0].slot = -1 if kind == "walk" else 1
		var ember: Dictionary = Rules.make_umbral("ember","resilient",2)
		ember.slot = 1 if kind == "walk" else 0
		game.party.append(ember)
		game.next_uid = 3
		if not run.choose_node("clearing"): return {}
		if kind == "ko":
			var aimed: bool = false
			for plan in game.enemy_plan:
				if str(plan.category) == "attack" and (int(plan.target_slot) == 1 or str(plan.get("scope","single")) != "single"): aimed = true
			if not aimed: continue
			game.party[0].hp = 1
			game.inventory.revive = 2
		game._sync_compatibility()
		var snapshot: Dictionary = run.snapshot()
		var checked = Expedition.new()
		if checked.restore(snapshot): return snapshot
	return {}

static func bind(app: Control, snapshot: Dictionary) -> bool:
	var candidate = Expedition.new()
	if snapshot.is_empty() or not candidate.restore(snapshot): return false
	app.feedback.cancel()
	app._start_game()
	app.session.expedition = candidate
	app.session.expedition_active = true
	app.runtime.bind_game(candidate.battle)
	app._sync_battle()
	app.screens.reset("battle")
	app._sync_phase()
	return true

static func settle(app: Control) -> bool:
	var deadline: int = Time.get_ticks_msec()+18000
	while app.runtime.turn.busy and Time.get_ticks_msec()<deadline: await app.get_tree().process_frame
	return not app.runtime.turn.busy

static func run(app: Control, expect: Callable, observe: Callable = Callable()) -> void:
	expect.call(bind(app,fixture("walk")),"Foli walk fixture restores a validated expedition")
	await app.get_tree().process_frame
	var hud: Control = app.screen_host.battle_root.hud
	app.runtime.commands.open_reserve(0)
	app.runtime.commands.queue_swap(1)
	expect.call(int(app.game.umbral_by_uid(1).slot) == -1,"Planning Foli's swap does not deploy or animate it")
	app.runtime.turn.cast()
	var rng_committed: int = app.game.rng.state
	await app.get_tree().create_timer(0.12).timeout
	var actor: Control = hud.actors[1]
	expect.call(int(actor.identity.uid)==1 and actor.rig.lifecycle.state=="walk","Only a confirmed swap starts Foli's own walk frames")
	var bounds: Rect2 = actor.get_global_rect()
	if observe.is_valid(): observe.call("walking",app)
	app._push("pause")
	var clock: float = actor.rig.lifecycle.elapsed
	await app.get_tree().create_timer(0.12).timeout
	expect.call(is_equal_approx(clock,actor.rig.lifecycle.elapsed),"Pause freezes Foli locomotion")
	app._pop()
	await settle(app)
	expect.call(not app.runtime.turn.busy and actor.get_global_rect()==bounds,"Walking returns control without moving the targetable slot")
	expect.call(app.game.rng.state==rng_committed,"Foli locomotion preserves committed gameplay RNG")
	expect.call(bind(app,fixture("ko")),"Foli damage fixture restores a validated expedition")
	await app.get_tree().process_frame
	hud = app.screen_host.battle_root.hud
	app.runtime.turn.redraw()
	var ko_settled: bool = await settle(app)
	expect.call(ko_settled,"Enemy damage feedback returns control within its bounded duration")
	actor = hud.actors[1]
	expect.call(int(actor.identity.hp)==0 and actor.rig.lifecycle.incapacitated,"Real enemy damage starts Foli incapacitation")
	await app.get_tree().create_timer(0.8).timeout
	expect.call(actor.rig.lifecycle.state=="ko" and actor.rig.lifecycle.sprite.frame==3,"The final KO pose stays after feedback completes")
	actor.stop_motion()
	expect.call(actor.rig.lifecycle.state=="ko","Canceling transient motion cannot clear an existing KO")
	if observe.is_valid(): observe.call("ko-held",app)
	app.preferences.set_value("reduced_motion",true)
	expect.call(actor.rig.lifecycle.sprite.frame==3 and actor.rig.lifecycle.active(),"Reduced motion keeps the final KO pose")
	app.preferences.set_value("reduced_motion",false)
	expect.call(app.game.queue_item("revive",1),"A real owned item can queue Foli recovery")
	app.runtime.turn.cast()
	await app.get_tree().create_timer(0.18).timeout
	expect.call(int(actor.identity.hp)>0 and not actor.rig.lifecycle.incapacitated,"Committed revive restores the same Foli individual")
	if observe.is_valid(): observe.call("reviving",app)
	var revive_settled: bool = await settle(app)
	expect.call(revive_settled,"Recovery feedback returns control within its bounded duration")
	await app.get_tree().create_timer(0.8).timeout
	expect.call(not actor.rig.lifecycle.active(),"Recovery settles to the normal rig without leaving a second silhouette")
	if observe.is_valid(): observe.call("recovered",app)
	app.feedback.cancel()
