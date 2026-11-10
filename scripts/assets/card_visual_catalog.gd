class_name UmbralCardVisualCatalog
extends RefCounted
## Exact presentation references over the existing asset catalog; no gameplay knowledge.
const Assets = preload("res://scripts/assets/catalog.gd")
const Paths = preload("res://scripts/assets/binding_paths.gd")
const BINDING: String = "ui/power-card-system"
const CACHE_LIMIT: int = 32
const PREVIEW_VERSION: String = "0.3.0"
static var preview_enabled: bool = false
static var _active: RefCounted
var _data: Dictionary = {}
var _allowed: Array = []
var _textures: Dictionary = {}
var _texture_profiles: Dictionary = {}
var _recent: Array[String] = []
var _missing: Dictionary = {}
var _production: bool = true
var _cache_limit: int = CACHE_LIMIT
var release_key: String = "unbound"

static func active() -> RefCounted:
	if _active != null: return _active
	_active = from_binding()
	if _active == null and (preview_enabled or (OS.has_feature("editor") and "--card-preview" in OS.get_cmdline_user_args())):
		_active = open_release(BINDING, PREVIEW_VERSION, true)
	return _active

static func from_binding() -> RefCounted:
	if not Paths.PATHS.has(BINDING): return null
	var module: Dictionary = Assets.bound_manifest(BINDING)
	return open_release(str(module.id), str(module.version))

static func open_release(asset_id: String, version: String, development: bool = false) -> RefCounted:
	var resolver = UmbralCardVisualCatalog.new()
	resolver.release_key = asset_id + "@" + version
	resolver._production = not development
	if not Assets.has_release(asset_id, version):
		resolver._record("presentation", resolver.release_key, "unknown_release")
		return resolver
	var module: Dictionary = Assets.manifest(asset_id, version)
	if module.is_empty() or not module.get("files", {}).has("presentation"):
		resolver._record("presentation", resolver.release_key, "missing_presentation")
		return resolver
	if not development and module.get("status") != "production":
		resolver._record("presentation", resolver.release_key, "not_production")
		return resolver
	var path: String = Assets.file_path(asset_id, version, "presentation")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or parsed.get("schema_version") != 1 or parsed.get("layout_version") != 1:
		resolver._record("presentation", resolver.release_key, "unsupported_contract")
		return resolver
	resolver._data = parsed
	resolver._allowed = module.dependencies.duplicate(true)
	resolver._allowed.append({"id": asset_id, "version": version})
	return resolver

func _record(kind: String, key: String, reason: String) -> Dictionary:
	var id: String = kind + ":" + key
	var diagnostic: Dictionary = {"kind": kind, "key": key, "reason": reason}
	if not _missing.has(id):
		_missing[id] = diagnostic
		push_warning("Card visual pending: " + id + " (" + reason + ")")
	return diagnostic

func _texture(entry: Dictionary, kind: String, key: String, issues: Array) -> Texture2D:
	var ref: Variant = entry.get("asset")
	if not ref is Dictionary:
		issues.append(_record(kind, key, "missing_asset"))
		return null
	var pair: Dictionary = {"id": str(ref.get("id", "")), "version": str(ref.get("version", ""))}
	if not pair in _allowed:
		issues.append(_record(kind, key, "unbound_reference"))
		return null
	if not Assets.has_release(pair.id, pair.version):
		issues.append(_record(kind, key, "unknown_release"))
		return null
	var module: Dictionary = Assets.manifest(pair.id, pair.version)
	var role: String = str(ref.get("role", ""))
	if module.is_empty() or module.get("files", {}).get(role, {}).get("kind") != "texture":
		issues.append(_record(kind, key, "invalid_texture_role"))
		return null
	if module.get("status") != "production" or entry.get("status") != "approved" or str(entry.get("review", "")).strip_edges().is_empty():
		issues.append(_record(kind, key, "not_approved"))
		if _production: return null
	var cache_key: String = pair.id + "@" + pair.version + ":" + role
	if _textures.has(cache_key):
		_recent.erase(cache_key)
		_recent.append(cache_key)
		_trim_cache()
		return _textures[cache_key]
	var path: String = Assets.file_path(pair.id, pair.version, role)
	var texture: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	if texture == null:
		issues.append(_record(kind, key, "texture_unavailable"))
		return null
	# The world deliberately uses nearest sampling for sprites. Painted card art
	# needs a complete reduction pyramid instead. Build it once per exact cached
	# reference, from the imported full-resolution image, also in a cold Web pack.
	# Never resize or modify the source PNG or globally replace its resource.
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		issues.append(_record(kind, key, "texture_pixels_unavailable"))
		return null
	if image.is_compressed() and image.decompress() != OK:
		issues.append(_record(kind, key, "texture_decode_failed"))
		return null
	if not image.has_mipmaps() and image.generate_mipmaps() != OK:
		issues.append(_record(kind, key, "texture_mipmaps_failed"))
		return null
	texture = ImageTexture.create_from_image(image)
	texture.resource_name = path
	_texture_profiles[cache_key] = {"source": path, "width": image.get_width(), "height": image.get_height(), "mipmap_count": image.get_mipmap_count(), "decoded_bytes_with_mipmaps": image.get_data_size()}
	_textures[cache_key] = texture
	_recent.append(cache_key)
	_trim_cache()
	return texture

func _trim_cache() -> void:
	while _recent.size() > maxi(1, _cache_limit):
		var key: String = _recent.pop_front()
		_textures.erase(key)
		_texture_profiles.erase(key)

static func texture_source(texture: Texture2D) -> String:
	return texture.resource_name if texture is ImageTexture else texture.resource_path

func resolve_owner_visual(species_id: String, form_id: String, power_id: String, power_nature: String) -> Dictionary:
	var key: String = "/".join([species_id, form_id, power_id])
	var issues: Array = []
	var family: Dictionary = _data.get("families", {}).get(species_id, {})
	var frame: Dictionary = family.get("form_overrides", {}).get(form_id, {})
	if frame.is_empty() and form_id in family.get("reuse_default_for_forms", []): frame = family.get("default_frame", {})
	var by_form: Dictionary = _data.get("illustrations", {}).get(species_id, {}).get(form_id, {})
	var art: Texture2D = _texture(by_form.get(power_id, {}), "illustration", key, issues)
	var border: Texture2D = _texture(frame, "frame", species_id + "/" + form_id, issues)
	var style: Dictionary = _data.get("power_styles", {}).get(power_nature, {})
	var tokens: Variant = style.get("tokens")
	var decorations: Dictionary = {"tokens": tokens.duplicate(true) if tokens is Dictionary else {}}
	if not tokens is Dictionary: issues.append(_record("tokens", power_nature, "missing_tokens"))
	for role: String in ["art_border", "title_plate", "owner_plate"]:
		decorations[role] = _texture(style.get(role, {}), role, power_nature, issues)
	return {"key": key, "release": release_key, "art": art, "frame": border, "style": decorations, "layout": _data.get("layout", {}).duplicate(true), "placeholder": not issues.is_empty(), "missing_entries": issues}

func resolve_target_visual(public_target: Dictionary) -> Dictionary:
	var kind: String = str(public_target.get("kind", "none"))
	var result: Dictionary = {"kind": kind, "label": str(public_target.get("label", "")), "uid": public_target.get("uid", -1), "texture": null, "missing_entries": []}
	if kind != "single": return result
	var source: String = str(public_target.get("portrait_source", "enemy_art" if public_target.get("enemy", false) else "form"))
	if source not in ["form", "enemy_art"]:
		result.missing_entries.append(_record("target", source, "unknown_portrait_source"))
		return result
	var portraits: String = "enemy_portraits" if source == "enemy_art" else "target_portraits"
	var key: String = str(public_target.get("portrait_key", ""))
	var entry: Dictionary = _data.get(portraits, {}).get(key, {})
	result.texture = _texture(entry, portraits, key, result.missing_entries)
	result.crop = entry.get("crop", [0, 0, 1, 1]).duplicate()
	result.focal_point = entry.get("focal_point", [0.5, 0.5]).duplicate()
	return result

func prewarm(keys: Array) -> void:
	for key: Dictionary in keys:
		resolve_owner_visual(str(key.species_id), str(key.form_id), str(key.power_id), str(key.nature))

func coverage_diagnostics() -> Dictionary:
	var decoded_bytes: int = 0
	for texture: Texture2D in _textures.values(): decoded_bytes += texture.get_width() * texture.get_height() * 4
	var prepared_bytes: int = 0
	for profile: Dictionary in _texture_profiles.values(): prepared_bytes += int(profile.decoded_bytes_with_mipmaps)
	return {"release": release_key, "missing_entries": _missing.values().duplicate(true), "cached_textures": _textures.size(), "cache_limit": maxi(1, _cache_limit), "estimated_rgba_bytes": decoded_bytes, "decoded_bytes_with_mipmaps": prepared_bytes, "texture_profiles": _texture_profiles.values().duplicate(true)}
