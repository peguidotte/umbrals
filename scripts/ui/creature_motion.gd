extends Node
## Playback only: never reads rules. Procedural clips and authored frame clips share one contract.
signal released(point_id: String)
const Direction = preload("res://scripts/catalog/direction_definition.gd")
const Clip = preload("res://scripts/catalog/clip_definition.gd")
var target: TextureRect
var definition: Direction
var current: Clip
var action: String = "idle"
var elapsed: float = 0.0
var idle_clock: float = 0.0
var phase_offset: float = 0.0
var reduced_motion: bool = false
var still: bool = false
var event_sent: bool = false
var textures: Dictionary[String, Texture2D] = {}

func configure(portrait: TextureRect, direction: Direction, uid: int) -> void:
	target = portrait
	definition = direction
	phase_offset = float(uid)
	textures.clear()
	for clip in definition.clips:
		for path in clip.frames:
			if not textures.has(path): textures[path] = load(path)
	target.texture = load(definition.portrait_path)
	target.flip_h = definition.mirror
	reset()

func reset() -> void:
	if is_instance_valid(target):
		target.scale = Vector2.ONE
		target.position = Vector2.ZERO
		target.modulate.a = 1.0
		if definition != null: target.texture = load(definition.portrait_path)
	action = "idle"
	elapsed = 0.0
	event_sent = false
	current = definition.clip("idle") if definition != null else null

func play(action_id: String) -> bool:
	if definition == null or definition.clip(action_id) == null: return false
	reset()
	action = action_id
	current = definition.clip(action_id)
	return true

func _process(delta: float) -> void:
	if current == null or not is_instance_valid(target): return
	if action == "idle" and (still or reduced_motion):
		target.position = Vector2.ZERO
		return
	elapsed += delta
	if action == "idle":
		idle_clock += delta
		target.position = current.pose_offset * sin(idle_clock * TAU / current.duration + phase_offset)
		if current.mode == "procedural": return
	var time: float = fmod(elapsed, current.duration) if current.loop else minf(elapsed, current.duration)
	var fraction: float = time / current.duration
	if not event_sent and not current.release_point.is_empty() and (reduced_motion or time >= current.release_time):
		event_sent = true
		released.emit(current.release_point)
	if current.mode == "frames" and not reduced_motion:
		var index: int = mini(current.frames.size() - 1, int(fraction * current.frames.size()))
		target.texture = textures[current.frames[index]]
	elif not reduced_motion:
		var weight: float = sin(fraction * PI)
		target.scale = Vector2.ONE.lerp(current.pose_scale, weight)
		target.position = current.pose_offset * weight * Vector2(-1 if definition.mirror else 1, 1)
	if not current.loop and (reduced_motion or elapsed >= current.duration): reset()
