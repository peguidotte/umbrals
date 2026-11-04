extends Node2D
## One action clock drives cast, anatomical emissions, actual hits and original sound.
const Motion = preload("res://scripts/ui/battle_motion.gd")
const Events = preload("res://scripts/ui/attack_events.gd")
const Renderer = preload("res://scripts/ui/battle_vfx.gd")
var renderer: Node2D
var epoch: int = 0
var active: bool = false
var suspended: bool = false
var started: int = 0
var current_variant: int = -1
var current_source: String = ""
var cycles: Dictionary = {}
var bodies: Array = []
var voice: AudioStreamPlayer
var voice_stream: AudioStream

func _ready() -> void:
	renderer = Renderer.new()
	add_child(renderer)
	show_behind_parent = true

func _exit_tree() -> void:
	cancel()

func cancel() -> void:
	epoch += 1
	active = false
	if is_instance_valid(voice) and voice.stream == voice_stream:
		voice.stop()
		voice.stream_paused = false
	voice = null
	voice_stream = null
	for body in bodies:
		if is_instance_valid(body): body.stop_motion()
	bodies.clear()
	if is_instance_valid(renderer): renderer.clear()

func set_suspended(value: bool) -> void:
	suspended = value
	if is_instance_valid(voice) and voice.stream == voice_stream: voice.stream_paused = value

func _key(event: Dictionary) -> String:
	return "%s:%d" % [str(event.get("target_side", "")), int(event.get("target_uid", -1))]

func play(events: Array, context: Dictionary, present: Callable) -> int:
	cancel()
	var token: int = epoch
	var first: Dictionary = events[0]
	var source: Control = Events.actor(first, context)
	if not is_instance_valid(source): return 0
	var power_key: String = "%s:%d:%s" % [str(first.actor_side), int(first.actor_uid), str(first.power)]
	var offset: int = {"ignivar": 1, "verdalio": 1, "mareveu": 1}.get(str(source.rig.form_id), 0)
	current_variant = Motion.variant_base(str(first.power), str(first.get("nature", ""))) + posmod(int(cycles.get(power_key, 0)) + offset, 3)
	cycles[power_key] = int(cycles.get(power_key, 0)) + 1
	var index: int = current_variant
	current_source = Motion.part(index)
	var spec: Dictionary = Motion.spec(index)
	var targets: Array = []
	var schedule: Array[float] = []
	var due: float = float(spec.contact)
	var mean_ground: Vector2 = Vector2.ZERO
	bodies = [source]
	renderer.index = index
	renderer.target_points.clear()
	renderer.target_families.clear()
	for event in events:
		if str(event.get("kind", "")) == "attack":
			var body: Control = Events.actor(event, context, true)
			due = float(spec.contact) + targets.size() * 0.045
			if is_instance_valid(body):
				targets.append({"body": body, "delay": targets.size() * 0.045, "weight": 0.3 if int(event.get("amount", 0)) == 0 else clampf(1.0 - float(event.get("resistance", 0)) * 0.004, 0.55, 1.0)})
				bodies.append(body)
				mean_ground += body.visual_ground()
				renderer.target_points.append(renderer.to_local(body.impact_point()))
				renderer.target_families.append(str(Motion.form(str(body.rig.form_id)).get("anatomy", {}).get("family", "")))
		schedule.append(due)
	if targets.is_empty():
		cancel()
		return 0
	mean_ground /= targets.size()
	var direction: float = -1.0 if source.enemy else 1.0
	var scale_factor: float = maxf(source.portrait.size.x, source.portrait.size.y) / 166.0
	var dash: Vector2 = mean_ground - source.visual_ground() - Vector2(direction * 80 * scale_factor, 0)
	var headroom: float = minf(mean_ground.y, source.visual_ground().y) - 118.0 * [0.90, 1.0, 1.07][clampi(source.slot, 0, 2)] - 32.0
	source.rig.jump_scale = clampf(headroom / maxf(1, 117 * scale_factor), 0.15, 1.0)
	source.rig.seek_cast(index, float(spec.release), dash)
	renderer.release_point = renderer.to_local(source.emission_point(index))
	source.rig.seek_cast(index, 0, dash)
	renderer.display_scale = scale_factor
	renderer.flashes = bool(context.preferences.flashes)
	renderer.reduced_motion = false
	active = true
	started += 1
	context.effects.flights += targets.size()
	voice = context.audio.performance(index)
	voice_stream = voice.stream if is_instance_valid(voice) else null
	var elapsed: float = 0.0
	var cursor: int = 0
	while elapsed < float(spec.end):
		await get_tree().process_frame
		if token != epoch or not is_instance_valid(source): return cursor
		if suspended: continue
		if bool(context.preferences.reduced_motion):
			cancel()
			return cursor
		elapsed += get_process_delta_time()
		source.rig.seek_cast(index, elapsed, dash)
		for target in targets:
			if not is_instance_valid(target.body): continue
			var age: float = elapsed - float(spec.contact) - float(target.delay)
			if age >= 0:
				target.body.rig.reaction_weight = float(target.weight)
				target.body.rig.seek_reaction(index, age)
		renderer.clock = elapsed
		renderer.source_point = renderer.to_local(source.emission_point(index))
		renderer.secondary_point = renderer.to_local(source.emission_point(index, true))
		renderer.body_point = renderer.to_local(source.rig.to_global(source.rig.project(Vector2(0.60, 0.50))))
		renderer.flashes = bool(context.preferences.flashes)
		renderer.queue_redraw()
		while cursor < events.size() and elapsed >= schedule[cursor]:
			present.call(events[cursor])
			cursor += 1
	if token != epoch: return cursor
	for body in bodies:
		if is_instance_valid(body): body.rig.managed = false
	source.stop_motion()
	bodies.clear()
	renderer.clear()
	active = false
	return cursor
