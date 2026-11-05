extends RefCounted
## Immutable tracks baked from the approved study. No session or gameplay state.
const Assets = preload("res://scripts/assets/catalog.gd")
const BINDING: String = "attacks/battle-performances"
static var data: Dictionary = {}
static var choreography: Dictionary = {}
static var form_overrides: Dictionary = {}

static func ensure_loaded() -> void:
	if not data.is_empty(): return
	var path: String = Assets.dependency_file(BINDING, "characters/battle-motion", "motion")
	data = JSON.parse_string(FileAccess.get_file_as_string(path))
	choreography = JSON.parse_string(FileAccess.get_file_as_string(Assets.bound_file(BINDING, "performances")))

static func form(id: String, view: String = "front") -> Dictionary:
	ensure_loaded()
	var key: String = id if view == "front" else id + ":" + view
	if not form_overrides.has(key):
		var binding: String = "umbrals/" + id
		var profile: Dictionary = Assets.bound_manifest(binding).get("metadata", {}).get("battle_profile", {})
		var role: String = str(profile.get("motion_role", ""))
		var motion_key: String = id if view == "front" else str(profile.get("views", {}).get(view, {}).get("motion_key", ""))
		var authored: Dictionary = {}
		if not role.is_empty() and not motion_key.is_empty():
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Assets.bound_file(binding, role)))
			if parsed is Dictionary: authored = parsed.get("forms", {}).get(motion_key, {})
		# A new pinned effect module can route existing, immutable own-body tracks.
		if not authored.is_empty() and not authored.has("attack_presentation"):
			var routed: Dictionary = Assets.bound_manifest("attacks/grass-leaf-blades").get("metadata", {}).get("actor_profiles", {}).get(id, {})
			if not routed.is_empty(): authored["attack_presentation"] = routed
		form_overrides[key] = authored
	if not form_overrides[key].is_empty(): return form_overrides[key]
	return data.forms.get(id, {}) if view == "front" else {}

static func spec(index: int) -> Dictionary:
	ensure_loaded()
	return choreography.specs[clampi(index, 0, 14)]

static func part(index: int) -> String:
	ensure_loaded()
	return str(choreography.parts[clampi(index, 0, 14)])

static func neutral() -> Array:
	return [0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

static func sample(id: String, mode: String, clip: int, time: float, view: String = "front") -> Array:
	var definition: Dictionary = form(id, view)
	if definition.is_empty():
		# Existing enemy illustrations inherit material pacing without borrowing
		# another creature's joints or changing their authored anatomy/identity.
		var proxy: String = {"spore": "moss", "owl": "volt", "stag": "ignivar"}.get(id, "")
		if view == "front" and not proxy.is_empty(): definition = data.forms.get(proxy, {})
	if definition.is_empty():
		var rest: Array = neutral()
		if mode == "states" and clip == 0:
			rest[3] = 1.0 + sin(time * 1.4) * 0.006
			rest[4] = 1.0 + sin(time * 1.4) * 0.009
		if mode == "reactions":
			var kick: float = sin(clampf(time / 0.65, 0, 1) * PI)
			rest[0] = -16 * kick
			rest[2] = 0.08 * kick
		return rest
	var tracks: Dictionary = definition.get(mode, definition.states)
	var frames: Array = tracks.get(str(clip), definition.states["0"])
	var position: float = clampf(time * 30.0, 0, frames.size() - 1)
	var first: int = floori(position)
	var second: int = mini(first + 1, frames.size() - 1)
	var result: Array = []
	for channel in range(frames[first].size()): result.append(lerpf(float(frames[first][channel]), float(frames[second][channel]), position - first))
	return result

static func socket(id: String, index: int, view: String = "front") -> Vector2:
	var anatomy: Dictionary = form(id, view).get("anatomy", {})
	var point: Array = anatomy.get(part(index), anatomy.get("mouth", [0.78, 0.48]))
	return Vector2(float(point[0]), float(point[1]))

static func variant_base(power: String, nature: String) -> int:
	match power:
		"fireball": return 0
		"thorn_lash": return 3
		"tidal_splash": return 6
		"lightning": return 9
		"storm_dive": return 12
	match nature:
		"fire": return 0
		"forest": return 3
		"water": return 6
		"lightning": return 9
	return 0
