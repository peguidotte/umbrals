extends RefCounted
## Event feedback owns only presentation nodes and the public resolution events.
const UI = preload("res://scripts/ui/kit.gd")
const Content = preload("res://scripts/content.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")
const BattleReadout = preload("res://scripts/ui/battle_readout.gd")
signal progress(index: int, total: int, line: String)
var generation: int = 0

func cancel() -> void:
	generation += 1

func play(result: Dictionary, context: Dictionary) -> void:
	var token: int = generation
	var actors: Array = context.actors
	var enemy_actors: Array = context.enemy_actors
	var audio: Node = context.audio
	var effects: Control = context.effects
	var preferences: Dictionary = context.preferences
	var reserves: Array = context.reserves
	var reserve_buttons: Array = context.reserve_buttons
	var viewport_size: Vector2 = context.viewport_size
	var tree: SceneTree = context.tree
	audio.duck()
	var events: Array = result.get("events", [])
	var effect_index: int = 0
	for event in events:
		if token != generation or not is_instance_valid(effects) or not is_instance_valid(audio): return
		effect_index += 1
		progress.emit(effect_index, events.size(), BattleReadout.event_line(event))
		var kind: String = str(event.get("kind", ""))
		var side: String = str(event.get("actor_side", "ally"))
		var source: Vector2 = _center(actors, enemy_actors, viewport_size, side, int(event.get("actor_slot", 1)))
		var target: Vector2 = _point(actors, enemy_actors, reserves, reserve_buttons, viewport_size, str(event.get("target_side", "enemy")), int(event.get("target_slot", 1)), int(event.get("target_uid", -1)))
		var amount: int = int(event.get("amount", 0))
		for actor in actors + enemy_actors:
			if not is_instance_valid(actor): continue
			actor.acting = not actor.identity.is_empty() and actor.enemy == (side == "enemy") and int(actor.identity.uid) == int(event.get("actor_uid", -1))
			actor.queue_redraw()
		if kind == "attack":
			var nature: Dictionary = Content.NATURES.get(str(event.get("nature", "")), {"name": "", "color": "b5a6f1"})
			var color: Color = Color(nature.color)
			var element: String = str(nature.name)
			effects.flight(source, target, color, element)
			audio.play("storm" if element == "Raio" else "leaf" if element in ["Água", "Bosque"] else "fire")
			await tree.create_timer(0.02 if preferences.reduced_motion else 0.22).timeout
			if token != generation or not is_instance_valid(effects) or not is_instance_valid(audio): return
			_snapshot(event, actors, enemy_actors, float(context.text_scale))
			if preferences.flashes:
				var slot: int = int(event.get("target_slot", -1))
				var targets: Array = enemy_actors if event.get("target_side", "enemy") == "enemy" else actors
				if slot >= 0 and slot < targets.size() and is_instance_valid(targets[slot]):
					var portrait: TextureRect = targets[slot].portrait
					var rest: Color = portrait.modulate
					portrait.modulate = Color(1.8, 1.8, 1.8)
					portrait.create_tween().tween_property(portrait, "modulate", rest, 0.08)
			effects.impact(target, amount)
			audio.play("impact")
			effects.popup(target + Vector2(0, -28), "BLOQUEADO" if amount == 0 else "−%d%s" % [amount, " RESISTIU" if int(event.get("resistance", 0)) > 0 else ""], UI.FIRE if side == "enemy" else UI.GOLD)
		elif kind == "reaction":
			_snapshot(event, actors, enemy_actors, float(context.text_scale))
			effects.burst(target, UI.GOLD, 12)
			effects.popup(target + Vector2(0, -52), str(event.label).to_upper(), UI.GOLD)
		elif kind == "condition":
			_snapshot(event, actors, enemy_actors, float(context.text_scale))
			var condition: String = str(event.get("condition", ""))
			effects.popup(target + Vector2(0, -6), str(Conditions.DEFINITIONS.get(condition, {}).get("name", condition)).to_upper(), UI.LEAF)
		elif kind == "condition_spent":
			_snapshot(event, actors, enemy_actors, float(context.text_scale))
		elif kind == "canceled":
			effects.popup(source, "NÃO AGIU", UI.MUTED)
		elif kind == "burn":
			_snapshot(event, actors, enemy_actors, float(context.text_scale))
			effects.burst(target, UI.FIRE, 8)
			effects.popup(target, "−%d QUEIMA" % amount, UI.FIRE)
		elif kind in ["heal", "revive", "block", "wet", "swap", "ko", "prepare"]:
			_snapshot(event, actors, enemy_actors, float(context.text_scale))
			var label: String = {"heal": "+%d HP" % amount, "revive": "REANIMADO", "block": "+%d ESCUDO" % amount, "wet": "ENCHARCADO", "swap": "TROCA", "ko": "INCAPACITADO", "prepare": "+%d CARGA" % amount}[kind]
			effects.popup(target, label, UI.LEAF if kind in ["heal", "revive"] else UI.GOLD)
			if kind in ["heal", "revive"]: audio.play("leaf")
		await tree.create_timer(0.01 if preferences.reduced_motion else 0.07).timeout
	if token != generation: return
	for actor in actors + enemy_actors:
		if not is_instance_valid(actor): continue
		actor.acting = false
		actor.queue_redraw()
	await tree.create_timer(0.03 if preferences.reduced_motion else 0.15).timeout

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
