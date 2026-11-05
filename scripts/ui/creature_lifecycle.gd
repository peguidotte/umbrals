extends Node2D
## Cosmetic locomotion/KO clips. Never moves the targetable slot or writes Rules.
const Assets = preload("res://scripts/assets/catalog.gd")
const BINDING: String = "characters/creature-lifecycle"
const SETTLE_SECONDS: float = 0.12
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
var settle_from: String = ""

func configure(form: String, dimensions: Vector2, pivot: Vector2, mirror: bool, reference: Dictionary = {}, view: String = "front") -> void:
	var release: Dictionary = Assets.bound_manifest(BINDING) if reference.is_empty() else Assets.manifest(str(reference.id), str(reference.version))
	var profile_key: String = form if view == "front" else form + ":" + view
	var next_key: String = "%s:%s:%s" % [str(release.get("id", "")), str(release.get("version", "")), profile_key]
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
			profile = data.get("forms", {}).get(profile_key, {})
		if not profile.is_empty():
			for animation in [str(profile.get("walk", "")), str(profile.get("ko", ""))]:
				if animation.is_empty(): continue
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

func enter() -> void:
	if profile.is_empty() or incapacitated or str(profile.get("walk", "")).is_empty(): return
	state = "walk"
	elapsed = 0.0
	_set_clip(str(profile.walk))
	_update_pose()

func set_incapacitated(value: bool, animate: bool = true) -> void:
	if profile.is_empty() or value == incapacitated: return
	incapacitated = value
	if str(profile.get("ko", "")).is_empty():
		state = ""
		_update_pose()
		return
	# Recovery reuses KO poses backwards; its visual quality still needs review.
	state = "ko" if value else "revive" if animate else ""
	elapsed = 0.0 if animate else float(profile.ko_seconds)
	if value or animate: _set_clip(str(profile.ko))
	_update_pose()

func cancel_transient() -> void:
	if not incapacitated and active():
		state = ""
		_update_pose()

func cancel_entry() -> void:
	if state == "walk" or (state == "settle" and settle_from == "walk"):
		state = ""
		_update_pose()

func advance(delta: float, paused: bool, reduced: bool) -> void:
	if not active(): return
	if reduced:
		if not incapacitated: state = ""
		else: elapsed = float(profile.ko_seconds)
	elif not paused:
		elapsed += delta
		var duration: float = float(profile.walk_seconds) if state == "walk" else float(profile.ko_seconds)
		if state in ["walk", "revive"] and elapsed >= duration:
			settle_from = state
			state = "settle"
			elapsed -= duration
		if state == "settle" and elapsed >= SETTLE_SECONDS: state = ""
	_update_pose()

func mesh_weight() -> float:
	# Different authored silhouettes must not create doubled heads/feet.
	if str(profile.get("settle_mode", "crossfade")) == "cut": return 0.0 if active() else 1.0
	if state == "settle": return clampf(elapsed / SETTLE_SECONDS, 0, 1)
	return 0.0 if active() else 1.0

func _set_clip(animation: String) -> void:
	sprite.sprite_frames = clips[animation]
	sprite.animation = animation
	sprite.stop()

func _update_pose() -> void:
	visible = active()
	if not visible or not is_instance_valid(sprite): return
	var walking: bool = state == "walk" or (state == "settle" and settle_from == "walk")
	var animation: String = str(profile.walk) if walking else str(profile.ko)
	var clip: Dictionary = manifest.animations[animation]
	var count: int = int(clip.frames)
	if state == "walk": sprite.frame = posmod(int(elapsed * float(clip.fps)), count)
	elif state == "revive": sprite.frame = maxi(0, count - 1 - int(elapsed * float(clip.fps)))
	elif state == "settle": sprite.frame = count - 1 if walking else 0
	else: sprite.frame = mini(count - 1, int(elapsed * float(clip.fps)))
	sprite.modulate.a = 1.0 - mesh_weight()
	sprite.scale = Vector2.ONE * uniform_scale
	sprite.position = -Vector2(float(clip.pivot[0]), float(clip.pivot[1])) * uniform_scale
	scale = Vector2(-1 if mirrored else 1, 1)
	position = anchor
	if state == "walk":
		var remaining: float = 1.0 - clampf(elapsed / float(profile.walk_seconds), 0, 1)
		position.x -= (1 if not mirrored else -1) * float(profile.stride_pixels) * uniform_scale * remaining
