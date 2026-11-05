extends Node2D
## Cosmetic pose playback. Contact/root samples share a clock; target slots never move.
const Assets = preload("res://scripts/assets/catalog.gd")
const BINDING: String = "characters/creature-lifecycle"
static var clip_cache: Dictionary = {}
var sprite: AnimatedSprite2D
var clips: Dictionary = {}
var profile: Dictionary = {}
var manifest: Dictionary = {}
var key: String = ""
var uniform_scale: float = 1.0
var anchor: Vector2 = Vector2.ZERO
var mirrored: bool = false
var incapacitated: bool = false
var state: String = ""
var elapsed: float = 0.0
var pose_index: int = 0
var pose_elapsed: float = 0.0
var first_tick: bool = false

func configure(form: String, dimensions: Vector2, pivot: Vector2, mirror: bool, reference: Dictionary = {}) -> void:
	var release: Dictionary = Assets.bound_manifest(BINDING) if reference.is_empty() else Assets.manifest(str(reference.id), str(reference.version))
	var next_key: String = "%s:%s:%s" % [str(release.get("id", "")), str(release.get("version", "")), form]
	if key != next_key:
		key = next_key
		manifest = release
		profile = {}
		clips = {}
		state = ""
		incapacitated = false
		if is_instance_valid(sprite): sprite.queue_free()
		sprite = null
		if not release.is_empty():
			var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Assets.file_path(str(release.id), str(release.version), "profile")))
			profile = data.get("forms", {}).get(form, {})
		if not profile.is_empty():
			for role in ["walk", "ko", "settle", "revive"]:
				if not profile.has(role): continue
				var animation: String = str(profile[role])
				var cache_key: String = "%s@%s:%s" % [str(release.id), str(release.version), animation]
				if not clip_cache.has(cache_key): clip_cache[cache_key] = Assets.sprite_frames(str(release.id), str(release.version), animation)
				clips[animation] = clip_cache[cache_key]
			sprite = AnimatedSprite2D.new()
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.centered = false
			add_child(sprite)
	anchor = Vector2(dimensions.x - pivot.x, pivot.y) if mirror else pivot
	mirrored = mirror
	if not profile.is_empty():
		uniform_scale = dimensions.y * float(profile.source_height_ratio) / float(profile.standing_height)
	_update_pose()

func active() -> bool:
	return not state.is_empty() and not profile.is_empty()

func _begin(next: String, animation: String) -> void:
	state = next
	elapsed = 0.0
	pose_elapsed = 0.0
	pose_index = 0
	first_tick = true
	sprite.sprite_frames = clips[animation]
	sprite.animation = animation
	sprite.stop()
	_update_pose()

func enter() -> void:
	if profile.is_empty() or incapacitated: return
	_begin("walk", str(profile.walk))

func set_incapacitated(value: bool, animate: bool = true) -> void:
	if profile.is_empty() or value == incapacitated: return
	incapacitated = value
	if value:
		_begin("ko", str(profile.ko))
		if not animate: pose_index = int(manifest.animations[str(profile.ko)].frames) - 1
	elif animate and profile.has("revive"):
		_begin("revive", str(profile.revive))
	else: state = ""
	_update_pose()

func cancel_transient() -> void:
	if not incapacitated and active():
		state = ""
		_update_pose()

func cancel_entry() -> void:
	if state in ["walk", "settle"]:
		state = ""
		_update_pose()

func advance(delta: float, paused: bool, reduced: bool) -> void:
	if not active(): return
	var count: int = int(manifest.animations[str(sprite.animation)].frames)
	if reduced:
		if not incapacitated: state = ""
		else: pose_index = count - 1
	elif not paused:
		if first_tick:
			first_tick = false
			_update_pose()
			return
		elapsed += delta
		pose_elapsed += delta
		var timeline: Array = profile.get("timelines", {}).get(str(sprite.animation), [])
		var dwell: float = float(timeline[pose_index].duration) if not timeline.is_empty() else 1.0 / float(manifest.animations[str(sprite.animation)].fps)
		# Never skip drawings after a slow render. Only this cosmetic clock stretches;
		# damage, casts and cancellation can still interrupt immediately.
		if delta > 0 and pose_elapsed + 0.000001 >= dwell:
			pose_elapsed = 0.0
			if pose_index + 1 < count: pose_index += 1
			elif state == "walk" and profile.has("settle"): _begin("settle", str(profile.settle))
			elif state != "ko": state = ""
	_update_pose()

func mesh_weight() -> float:
	return 0.0 if active() else 1.0

func _update_pose() -> void:
	visible = active()
	if not visible or not is_instance_valid(sprite): return
	var animation: String = str(sprite.animation)
	var clip: Dictionary = manifest.animations[animation]
	sprite.frame = pose_index
	sprite.modulate.a = 1.0
	sprite.scale = Vector2.ONE * uniform_scale
	sprite.position = -Vector2(float(clip.pivot[0]), float(clip.pivot[1])) * uniform_scale
	scale = Vector2(-1 if mirrored else 1, 1)
	position = anchor
	var timeline: Array = profile.get("timelines", {}).get(animation, [])
	if not timeline.is_empty():
		var offset: Array = timeline[pose_index].offset
		position += Vector2(float(offset[0]) * (-1 if mirrored else 1), float(offset[1])) * uniform_scale
