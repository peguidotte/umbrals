extends Node
signal finished
signal resumed
var timer: Timer
const UI = preload("res://scripts/ui/kit.gd")
const Models = preload("res://scripts/domain/models.gd")
const Ids = preload("res://scripts/domain/ids.gd")
const Content = preload("res://scripts/content.gd")
const Summary = preload("res://scripts/ui/combat_event_summary.gd")
const Battle = preload("res://scripts/ui/screens/battle_view.gd")
const Preferences = preload("res://scripts/ui/preferences.gd")
const Audio = preload("res://scripts/ui/audio.gd")
var busy: bool = false
var generation: int = 0
var tweens: Array[Tween] = []
var labels: Array[Label] = []
var release_connections: Array[Dictionary] = []
var view: Battle
var ui: UI
var preferences: Preferences
var audio: Audio

func _ready() -> void:
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(resumed.emit)

func _exit_tree() -> void:
	cancel()

func _wait(seconds: float) -> void:
	timer.start(seconds)
	await resumed

func configure(kit: UI, prefs: Preferences, sound: Audio) -> void:
	ui = kit
	preferences = prefs
	audio = sound

func begin() -> void:
	cancel()
	busy = true

func cancel() -> void:
	generation += 1
	busy = false
	if is_instance_valid(timer): timer.stop()
	resumed.emit()
	for connection in release_connections:
		if is_instance_valid(connection.actor) and connection.actor.action_released.is_connected(connection.callback):
			connection.actor.action_released.disconnect(connection.callback)
	release_connections.clear()
	for tween in tweens:
		if tween.is_valid(): tween.kill()
	tweens.clear()
	for label in labels:
		if is_instance_valid(label): label.queue_free()
	labels.clear()
	if is_instance_valid(view):
		view.effects.clear()
		view.enemy_art.scale = Vector2.ONE
		view.enemy_art.modulate = Color.WHITE
		for actor in view.actors: actor.cancel_action()

func track(tween: Tween) -> Tween:
	tweens.append(tween)
	return tween

func present(battle: Battle, result: Models.ResolutionResult, _cards: Array[Models.CardInstance], device: String) -> void:
	view = battle
	var token: int = generation
	var score: Models.CastEvaluation = result.evaluation
	var events = Summary.new(result.combat_events)
	audio.duck()
	var target: Vector2 = view.enemy_art.get_global_rect().get_center()
	var impact_delay: float = UI.tokens.motion.projectile
	for actor in view.actors:
		if actor.identity == null: continue
		if not events.actions.has(actor.identity.uid): continue
		var event = events.actions[actor.identity.uid]
		var action_id: String = event.action_id
		var color: Color = view.game.catalog.species[actor.identity.species_id].color
		var callback: Callable = func(action: String, origin: Vector2):
			if token == generation and action == "attack_ranged": view.effects.flight(origin, target, color)
		actor.action_released.connect(callback)
		release_connections.append({"actor": actor, "callback": callback})
		var clip = actor.motion.definition.clip(action_id)
		if action_id == "attack_ranged": impact_delay = maxf(impact_delay, clip.release_time + UI.tokens.motion.projectile)
		actor.play_action(action_id)
		audio.play(event.sound_id)
	view.navigation.changed.emit()
	await _wait(UI.tokens.motion.reduced_pause if preferences.values.reduced_motion else impact_delay)
	if token != generation or not is_instance_valid(view): return
	view.render(true, device, true)
	if events.damage > 0:
		view.effects.impact(target, int(events.damage))
		audio.play("impact")
		_float_text("−%d" % events.damage, target + Vector2(20, -50), UI.tokens.gold, 48)
		if not preferences.values.reduced_motion:
			view.enemy_art.scale = Vector2(1.06, 0.96)
			track(view.enemy_art.create_tween()).tween_property(view.enemy_art, "scale", Vector2.ONE, UI.tokens.motion.impact).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if int(events.burn) > 0: _float_text("QUEIMA %d" % events.burn, target + Vector2(28, 10), UI.tokens.fire, 22)
		if preferences.values.flashes:
			view.enemy_art.modulate = Color(1.6, 1.5, 1.3)
			track(view.enemy_art.create_tween()).tween_property(view.enemy_art, "modulate", Color.WHITE, UI.tokens.motion.flash)
	var healing: int = events.healing
	if healing > 0: _float_text("+%d CURA" % healing, view.player_vitals.get_global_rect().get_center() + Vector2(80, 40), UI.tokens.leaf, 28)
	if int(events.incoming) > 0: _float_text("−%d" % events.incoming, view.player_vitals.get_global_rect().get_center() + Vector2(25, 20), UI.tokens.fire, 32)
	if Ids.TRIPLE_LINK in score.events: _float_text("VÍNCULO TRIPLO", view.size * Vector2(0.5, 0.32), UI.tokens.gold, 32)
	await _wait(UI.tokens.motion.reduced_pause if preferences.values.reduced_motion else UI.tokens.motion.recovery)
	if token != generation or not is_instance_valid(view): return
	busy = false
	finished.emit()

func _float_text(text: String, point: Vector2, color: Color, font_size: int) -> void:
	var label: Label = ui.label(text, font_size, color, true, true)
	view.effects.add_child(label)
	labels.append(label)
	label.position = point - Vector2(140, 20)
	label.size = Vector2(280, 56)
	var tween = track(label.create_tween().set_parallel(true))
	if not preferences.values.reduced_motion:
		tween.tween_property(label, "position:y", label.position.y - 36, UI.tokens.motion.float_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, UI.tokens.motion.fade_duration).set_delay(UI.tokens.motion.fade_delay)
	tween.chain().tween_callback(label.queue_free)

func float_text(battle: Battle, text: String, point: Vector2, color: Color, font_size: int) -> void:
	view = battle
	_float_text(text, point, color, font_size)
