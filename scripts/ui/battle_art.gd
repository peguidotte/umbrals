class_name UmbralBattleArt
extends RefCounted
## Atlas regions are applied at render time. Generated source PNGs stay untouched.
const Assets = preload("res://scripts/assets/catalog.gd")
const ATLAS_MODULES = ["characters/battle-creatures", "characters/battle-evolved"]
const ATLAS_VERSION = "1.0.0"
static var _loaded: bool = false
static var _textures: Dictionary = {}
static var _grounding: Dictionary = {}

static func texture(art_id: String) -> Texture2D:
	var region_id: String = art_id.get_file()
	if _textures.has(region_id): return _textures[region_id]
	if not _loaded:
		_loaded = true
		for module_id in ATLAS_MODULES:
			var map_path: String = Assets.file_path(module_id, ATLAS_VERSION, "atlas")
			if not FileAccess.file_exists(map_path): continue
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(map_path))
			if not parsed is Dictionary or not parsed.get("regions") is Dictionary: continue
			var atlas_path: String = Assets.file_path(module_id, ATLAS_VERSION, "texture")
			if not ResourceLoader.exists(atlas_path): continue
			var atlas: Texture2D = load(atlas_path)
			for key in parsed.regions:
				var rectangle: Variant = parsed.regions[key]
				if not rectangle is Array or rectangle.size() != 4: continue
				var region = AtlasTexture.new()
				region.atlas = atlas
				region.region = Rect2(float(rectangle[0]), float(rectangle[1]), float(rectangle[2]), float(rectangle[3]))
				region.filter_clip = true
				_textures[str(key)] = region
				if parsed.get("grounding", {}).get(key) is Dictionary:
					_grounding[str(key)] = parsed.grounding[key]
	if _textures.has(region_id): return _textures[region_id]
	var result: Texture2D = Assets.texture(art_id)
	_textures[region_id] = result
	return result

static func ground_profile(art_id: String) -> Dictionary:
	var art: Texture2D = texture(art_id)
	return _grounding.get(art_id.get_file(), {"foot": [art.get_width() * 0.5, art.get_height() * 0.93], "width": art.get_width() * 0.6, "visible_top": art.get_height() * 0.10})
