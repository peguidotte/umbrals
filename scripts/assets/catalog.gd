class_name UmbralAssets
extends RefCounted
## Logical game bindings are pinned in runtime-lock.json, never resolved by "latest".
## Prototype clips require an explicit module ID, version and animation name.
const Paths = preload("res://scripts/assets/binding_paths.gd")
static var _catalog: Dictionary = {}
static var _manifests: Dictionary = {}

static func resource(binding: String) -> Resource:
	if not Paths.PATHS.has(binding):
		push_error("Unknown pinned asset binding: " + binding)
		return null
	return load(String(Paths.PATHS[binding]))

static func texture(binding: String) -> Texture2D:
	return resource(binding) as Texture2D

static func manifest(asset_id: String, version: String) -> Dictionary:
	var key: String = asset_id + "@" + version
	if _manifests.has(key): return _manifests[key].duplicate(true)
	if _catalog.is_empty():
		_catalog = _read_json("res://assets/catalog.json")
	var modules: Dictionary = _catalog.get("modules", {})
	if not modules.has(asset_id) or not modules[asset_id].versions.has(version):
		push_error("Unknown explicit asset release: " + key)
		return {}
	var data: Dictionary = _read_json("res://" + String(modules[asset_id].versions[version].manifest))
	_manifests[key] = data
	return data.duplicate(true)

static func file_path(asset_id: String, version: String, role: String) -> String:
	var data: Dictionary = manifest(asset_id, version)
	if data.is_empty() or not data.files.has(role):
		push_error("Unknown asset role: %s@%s:%s" % [asset_id, version, role])
		return ""
	var entry: Dictionary = _catalog.modules[asset_id].versions[version]
	return "res://" + String(entry.manifest).get_base_dir().path_join(String(data.files[role].path))

static func sprite_frames(asset_id: String, version: String, animation: String, low_quality: bool = false) -> SpriteFrames:
	var data: Dictionary = manifest(asset_id, version)
	if data.is_empty() or not data.get("animations", {}).has(animation):
		push_error("Unknown asset animation: %s@%s:%s" % [asset_id, version, animation])
		return null
	var clip: Dictionary = data.animations[animation]
	var pages: Array = clip.get("pages", [])
	if pages.is_empty(): pages = [{"file": clip.file, "frames": clip.frames, "low_file": clip.get("low_file", "")}]
	var ratio: float = 0.5 if low_quality and not String(pages[0].get("low_file", "")).is_empty() else 1.0
	var cell: Vector2 = Vector2(float(clip.frame_size[0]), float(clip.frame_size[1])) * ratio
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(animation)
	frames.set_animation_speed(animation, float(clip.fps))
	frames.set_animation_loop(animation, bool(clip.loop))
	for page: Dictionary in pages:
		var role: String = String(page.low_file if ratio == 0.5 else page.file)
		var atlas: Texture2D = load(file_path(asset_id, version, role)) as Texture2D
		if atlas == null: return null
		for index in range(int(page.frames)):
			var frame: AtlasTexture = AtlasTexture.new()
			frame.atlas = atlas
			frame.region = Rect2(Vector2(index % int(clip.columns), floori(index / float(clip.columns))) * cell, cell)
			frame.filter_clip = true
			frames.add_frame(animation, frame)
	return frames

static func sprite_layout(asset_id: String, version: String, animation: String, low_quality: bool = false) -> Dictionary:
	var data: Dictionary = manifest(asset_id, version)
	if data.is_empty() or not data.get("animations", {}).has(animation): return {}
	var clip: Dictionary = data.animations[animation]
	var has_low: bool = clip.has("low_file") or (clip.has("pages") and clip.pages[0].has("low_file"))
	var ratio: float = 0.5 if low_quality and has_low else 1.0
	var cell: Vector2 = Vector2(float(clip.frame_size[0]), float(clip.frame_size[1])) * ratio
	var pivot: Vector2 = Vector2(float(clip.pivot[0]), float(clip.pivot[1])) * ratio
	var display: Array = clip.get("display_size", clip.frame_size)
	return {"offset": cell * 0.5 - pivot, "scale": Vector2(float(display[0]), float(display[1])) / cell}

static func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Invalid asset JSON: " + path)
		return {}
	return parsed
