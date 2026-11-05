extends RefCounted
## Optional per-form presentation lives in its exact art binding, independent of rules.
const Assets = preload("res://scripts/assets/catalog.gd")
static var presentations: Dictionary = {}
static var motions: Dictionary = {}

static func form(id: String) -> Dictionary:
	var binding: String = "umbrals/" + id
	if not presentations.has(binding):
		presentations[binding] = _data(binding, "presentation")
	return presentations[binding].get("forms", {}).get(id, {})

static func motion(id: String) -> Dictionary:
	if form(id).is_empty(): return {}
	var binding: String = "umbrals/" + id
	if not motions.has(binding): motions[binding] = _data(binding, "motion")
	return motions[binding].get("forms", {}).get(id, {})

static func texture(id: String, enemy: bool) -> Texture2D:
	var definition: Dictionary = form(id)
	if definition.is_empty(): return null
	var side: Dictionary = definition["enemy" if enemy else "ally"]
	var image: Texture2D = load(Assets.bound_file("umbrals/" + id, str(side.texture)))
	var region := AtlasTexture.new()
	region.atlas = image
	region.region = Rect2(Vector2.ZERO, image.get_size())
	region.filter_clip = true
	return region

static func ko_texture(id: String, enemy: bool) -> Texture2D:
	var definition: Dictionary = form(id)
	if definition.is_empty(): return null
	var role: String = str(definition["enemy" if enemy else "ally"].get("ko_texture", ""))
	return load(Assets.bound_file("umbrals/" + id, role)) as Texture2D if not role.is_empty() else null

static func _data(binding: String, role: String) -> Dictionary:
	if not Assets.bound_manifest(binding).get("files", {}).has(role): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Assets.bound_file(binding, role)))
	return parsed if parsed is Dictionary else {}
