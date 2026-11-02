class_name UmbralReferenceArt
extends RefCounted
const Assets = preload("res://scripts/assets/catalog.gd")
const SIZE = Vector2(1672, 941)
static func region(binding: String, rect: Rect2) -> AtlasTexture:
	var result = AtlasTexture.new()
	result.atlas = Assets.texture(binding)
	result.region = rect
	result.filter_clip = true
	return result
static func image(parent: Control, texture: Texture2D, rect: Rect2) -> TextureRect:
	var view = TextureRect.new()
	view.texture = texture
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(view)
	view.position = rect.position
	view.size = rect.size
	return view
static func patch(parent: Control, binding: String, rect: Rect2, destination: Rect2 = Rect2()) -> TextureRect:
	return image(parent, region(binding, rect), rect if destination.size == Vector2.ZERO else destination)
static func layout(root: Control, canvas: Control) -> void:
	var factor: float = minf(root.size.x / SIZE.x, root.size.y / SIZE.y)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (root.size - SIZE * factor) * 0.5
static func native(parent: Control, control: Control, rect: Rect2) -> void:
	parent.add_child(control)
	control.position = rect.position
	control.size = rect.size
