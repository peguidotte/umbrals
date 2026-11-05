extends Node2D
## Cosmetic locomotion/KO clips. Never moves the targetable slot or writes Rules.
const Assets = preload("res://scripts/assets/catalog.gd")
const BINDING: String = "characters/creature-lifecycle"
var sprite: AnimatedSprite2D
var profile: Dictionary = {}
var manifest: Dictionary = {}
var key: String = ""
var uniform_scale: float = 1.0
var anchor: Vector2 = Vector2.ZERO
var mirrored: bool = false
var incapacitated: bool = false
var state: String = ""
var elapsed: float = 0.0

func configure(form: String, dimensions: Vector2, pivot: Vector2, mirror: bool, reference: Dictionary = {}) -> void:
	var release: Dictionary = Assets.bound_manifest(BINDING) if reference.is_empty() else Assets.manifest(str(reference.id), str(reference.version))
	var next_key: String = "%s:%s:%s" % [str(release.get("id", "")), str(release.get("version", "")), form]
	if key != next_key:
		key = next_key
		manifest = release
		profile = {}
		state = ""
		incapacitated = false
		if is_instance_valid(sprite): sprite.queue_free()
		sprite = null
		if not release.is_empty():
			var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Assets.file_path(str(release.id), str(release.version), "profile")))
			profile = data.get("forms", {}).get(form, {})
		if not profile.is_empty():
			sprite = AnimatedSprite2D.new()
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.centered = false
			add_child(sprite)
	anchor = pivot
	mirrored = mirror
	if not profile.is_empty():
		uniform_scale = dimensions.y * float(profile.source_height_ratio) / float(profile.standing_height)
	_update_pose()

func active() -> bool:
	return not state.is_empty() and not profile.is_empty()

func enter() -> void:
	if profile.is_empty() or incapacitated: return
	state = "walk"
	elapsed = 0.0
	_set_clip(str(profile.walk))
	_update_pose()

func set_incapacitated(value: bool, animate: bool = true) -> void:
	if profile.is_empty() or value == incapacitated: return
	incapacitated = value
	state = "ko" if value else ""
	elapsed = 0.0 if animate else float(profile.ko_seconds)
	if value: _set_clip(str(profile.ko))
	_update_pose()

func cancel_walk() -> void:
	if state == "walk":
		state = ""
		_update_pose()

func advance(delta: float, paused: bool, reduced: bool) -> void:
	if not active(): return
	if reduced:
		if state == "walk": state = ""
		else: elapsed = float(profile.ko_seconds)
	elif not paused:
		elapsed += delta
		if state == "walk" and elapsed >= float(profile.walk_seconds): state = ""
	_update_pose()

func _set_clip(animation: String) -> void:
	sprite.sprite_frames = Assets.sprite_frames(str(manifest.id), str(manifest.version), animation)
	sprite.animation = animation
	sprite.stop()

func _update_pose() -> void:
	visible = active()
	if not visible or not is_instance_valid(sprite): return
	var animation: String = str(profile.walk) if state == "walk" else str(profile.ko)
	var clip: Dictionary = manifest.animations[animation]
	var count: int = int(clip.frames)
	sprite.frame = posmod(int(elapsed * float(clip.fps)), count) if state == "walk" else mini(count - 1, int(elapsed * float(clip.fps)))
	sprite.scale = Vector2.ONE * uniform_scale
	sprite.position = -Vector2(float(clip.pivot[0]), float(clip.pivot[1])) * uniform_scale
	scale = Vector2(-1 if mirrored else 1, 1)
	position = anchor
	if state == "walk":
		var remaining: float = 1.0 - clampf(elapsed / float(profile.walk_seconds), 0, 1)
		position.x -= (1 if not mirrored else -1) * float(profile.stride_pixels) * uniform_scale * remaining
