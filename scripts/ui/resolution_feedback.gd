extends RefCounted
## Public event snapshots are applied at the corresponding visual contact.
const UI = preload("res://scripts/ui/kit.gd")
const Content = preload("res://scripts/content.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")
const BattleReadout = preload("res://scripts/ui/battle_readout.gd")
const AttackEvents = preload("res://scripts/ui/attack_events.gd")
signal progress(index: int, total: int, line: String)
var generation: int = 0
var active_performance: Node

func cancel() -> void:
	generation += 1
	if is_instance_valid(active_performance): active_performance.cancel()
	active_performance = null

func _publish(event: Dictionary, counter: Dictionary, total: int) -> void:
	counter.index += 1
	progress.emit(int(counter.index), total, BattleReadout.event_line(event))

func play(result: Dictionary, context: Dictionary) -> void:
	var token: int = generation
	var effects: Control = context.effects
	var audio: Node = context.audio
	var events: Array = result.get("events", [])
	var counter: Dictionary = {"index": 0}
	var skip_until: int = 0
	audio.duck()
	for position in range(events.size()):
		if position < skip_until: continue
		if token != generation or not is_instance_valid(effects) or not is_instance_valid(audio): return
		var event: Dictionary = events[position]
		for actor in context.actors + context.enemy_actors:
			if not is_instance_valid(actor): continue
			actor.acting = not actor.identity.is_empty() and actor.enemy == (event.get("actor_side", "ally") == "enemy") and int(actor.identity.uid) == int(event.get("actor_uid", -1))
			actor.queue_redraw()
		_publish(event, counter, events.size())
		if event.get("kind", "") == "attack" and not context.preferences.reduced_motion:
			var group: Dictionary = AttackEvents.collect(events, position)
			skip_until = int(group.next)
			active_performance = effects.choreography
			var delivered: Dictionary = {"first": true}
			var callback: Callable = func(hit: Dictionary):
				if token != generation or not is_instance_valid(effects): return
				if delivered.first: delivered.first = false
				else: _publish(hit, counter, events.size())
				_present(hit, context, true)
			var processed: int = await active_performance.play(group.events, context, callback)
			if token != generation or not is_instance_valid(effects): return
			for remaining in group.events.slice(processed): callback.call(remaining)
			active_performance = null
			continue
		if event.get("kind", "") == "attack":
			var from: Vector2 = _center(context.actors, context.enemy_actors, context.viewport_size, str(event.actor_side), int(event.actor_slot))
			var to: Vector2 = _point(context.actors, context.enemy_actors, context.reserves, context.reserve_buttons, context.viewport_size, str(event.target_side), int(event.target_slot), int(event.target_uid))
			var nature: Dictionary = Content.NATURES.get(str(event.get("nature", "")), {"name": "", "color": "b5a6f1"})
			effects.flight(from, to, Color(nature.color), str(nature.name))
			await context.tree.create_timer(0.02).timeout
			if token != generation or not is_instance_valid(effects): return
		_present(event, context, false)
		await context.tree.create_timer(0.01 if context.preferences.reduced_motion else 0.07).timeout
	if token != generation: return
	for actor in context.actors + context.enemy_actors:
		if not is_instance_valid(actor): continue
		actor.acting = false
		if result.get("phase", "") in ["victory", "reward"] and not actor.enemy and not actor.identity.is_empty() and int(actor.identity.get("hp", 0)) > 0: actor.rig.play_state(5)
		actor.queue_redraw()
	await context.tree.create_timer(0.03 if context.preferences.reduced_motion else 0.15).timeout

func _present(event: Dictionary, context: Dictionary, illustrated: bool) -> void:
	var effects: Control = context.effects
	var kind: String = str(event.get("kind", ""))
	var side: String = str(event.get("actor_side", "ally"))
	var body: Control = AttackEvents.actor(event, context, true)
	var target: Vector2 = body.impact_point() if is_instance_valid(body) else _point(context.actors, context.enemy_actors, context.reserves, context.reserve_buttons, context.viewport_size, str(event.get("target_side", "enemy")), int(event.get("target_slot", 1)), int(event.get("target_uid", -1)))
	var amount: int = int(event.get("amount", 0))
	_snapshot(event, context.actors, context.enemy_actors, float(context.text_scale))
	match kind:
		"attack":
			if illustrated:
				effects.hits += 1
				var variant: int = int(effects.choreography.current_variant)
				var impulse: float = 0.78 if variant >= 12 or amount >= 35 else 0.72 if variant == 4 else 0.52
				effects.trauma = maxf(effects.trauma, impulse) if not context.preferences.reduced_motion else 0.0
			else:
				effects.impact(target, amount)
				context.audio.play("impact")
			effects.popup(target + Vector2(0, -28), "BLOQUEADO" if amount == 0 else "−%d%s" % [amount, " RESISTIU" if int(event.get("resistance", 0)) > 0 else ""], UI.FIRE if side == "enemy" else UI.GOLD)
		"reaction":
			effects.burst(target, UI.GOLD, 12)
			effects.popup(target + Vector2(0, -52), str(event.label).to_upper(), UI.GOLD)
		"condition":
			var condition: String = str(event.get("condition", ""))
			effects.popup(target + Vector2(0, -6), str(Conditions.DEFINITIONS.get(condition, {}).get("name", condition)).to_upper(), UI.LEAF)
		"canceled":
			effects.popup(_center(context.actors, context.enemy_actors, context.viewport_size, side, int(event.get("actor_slot", 1))), "NÃO AGIU", UI.MUTED)
		"burn":
			effects.burst(target, UI.FIRE, 8)
			effects.popup(target, "−%d QUEIMA" % amount, UI.FIRE)
		"heal", "revive", "block", "wet", "swap", "ko", "prepare":
			var label: String = {"heal": "+%d HP" % amount, "revive": "REANIMADO", "block": "+%d ESCUDO" % amount, "wet": "ENCHARCADO", "swap": "TROCA", "ko": "INCAPACITADO", "prepare": "+%d CARGA" % amount}[kind]
			effects.popup(target, label, UI.LEAF if kind in ["heal", "revive"] else UI.GOLD)
			if kind in ["heal", "revive"]: context.audio.play("leaf")
			if is_instance_valid(body) and kind in ["block", "prepare", "heal", "revive"] and not illustrated: body.rig.play_state(4 if kind == "block" else 1 if kind == "prepare" else 5)

func _center(actors: Array, enemies: Array, viewport: Vector2, side: String, slot: int) -> Vector2:
	var list: Array = actors if side == "ally" else enemies
	if slot < 0 or slot >= list.size() or not is_instance_valid(list[slot]): return viewport * Vector2(0.5, 0.35)
	return list[slot].get_global_rect().get_center() - Vector2(0, 12)

func _point(actors: Array, enemies: Array, reserves: Array, buttons: Array, viewport: Vector2, side: String, slot: int, uid: int) -> Vector2:
	if side == "ally" and slot < 0:
		for index in range(reserves.size()):
			if int(reserves[index].uid) == uid and index < buttons.size() and is_instance_valid(buttons[index]):
				return buttons[index].get_global_rect().get_center() - Vector2(0, 18)
	return _center(actors, enemies, viewport, side, slot)

func _snapshot(event: Dictionary, actors: Array, enemies: Array, text_scale: float) -> void:
	var slot: int = int(event.get("target_slot", -1))
	var snapshot: Dictionary = event.get("target_state", {})
	if slot < 0 or slot >= 3 or snapshot.is_empty(): return
	var targets: Array = enemies if event.get("target_side", "enemy") == "enemy" else actors
	if slot < targets.size() and is_instance_valid(targets[slot]): targets[slot].set_identity(snapshot, text_scale)
