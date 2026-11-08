extends Node2D
## Existing canonical pose pixels; one decorative clock, no session state.
const Assets = preload("res://scripts/assets/catalog.gd")
var frames: SpriteFrames
var sprite: Sprite2D
var clip: String
var source_path: String
var spec: Dictionary
var pivot: Vector2
var anchor: Vector2
var display_size: Vector2
var standing_height: float
var base_scale: float = 1.0
var frame: int = 3

func build(value: Dictionary) -> void:
	spec = value
	var binding: String = str(spec.binding)
	var manifest: Dictionary = Assets.bound_manifest(binding)
	clip = str(spec.clip)
	frames = Assets.sprite_frames(str(manifest.id),str(manifest.version),clip)
	var animation: Dictionary = manifest.animations[clip]
	pivot = Vector2(float(animation.pivot[0]),float(animation.pivot[1]))
	source_path = Assets.bound_file(binding,str(animation.file))
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Assets.bound_file(binding,"profile")))
	standing_height = float(profile.forms[str(spec.form)].standing_height)
	sprite = Sprite2D.new()
	sprite.centered = false
	add_child(sprite)
	sample(0.0,-1.0,1.0,true)

func place(feet: Vector2, height: float) -> void:
	anchor = feet
	base_scale = height*0.86/standing_height
	display_size = frames.get_frame_texture(clip,0).get_size()*base_scale
	_transform(1.0)

func sample(clock: float, reaction: float, duration: float, still: bool) -> void:
	frame = int(spec.rest_frame)
	if reaction >= 0.0 and not still:
		var progress: float = clampf(reaction/duration,0.0,1.0)
		for key: Array in spec.wake:
			if progress >= float(key[0]): frame = int(key[1])
	sprite.texture = frames.get_frame_texture(clip,frame)
	var breath: float = 1.0 if still else 1.0+sin(clock*TAU/float(spec.breathing_duration))*float(spec.breathing_scale)
	_transform(breath)

func _transform(breath: float) -> void:
	sprite.scale = Vector2.ONE*base_scale*breath
	sprite.position = anchor-pivot*sprite.scale
