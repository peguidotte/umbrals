extends RefCounted
## Immutable tracks baked from the approved study. No session or gameplay state.
const Assets = preload("res://scripts/assets/catalog.gd")
const Presentation = preload("res://scripts/ui/creature_presentation.gd")
const BINDING: String = "attacks/battle-performances"
static var data: Dictionary = {}
static var choreography: Dictionary = {}

static func ensure_loaded() -> void:
	if not data.is_empty(): return
	var path: String = Assets.dependency_file(BINDING, "characters/battle-motion", "motion")
	data = JSON.parse_string(FileAccess.get_file_as_string(path))
	choreography = JSON.parse_string(FileAccess.get_file_as_string(Assets.bound_file(BINDING, "performances")))

static func form(id: String) -> Dictionary:
	var authored: Dictionary = Presentation.motion(id)
	if not authored.is_empty(): return authored
	ensure_loaded()
	return data.forms.get(id, {})

static func spec(index: int) -> Dictionary:
	ensure_loaded()
	return choreography.specs[clampi(index, 0, 14)]

static func part(index: int, id: String = "") -> String:
	if not id.is_empty():
		var parts: Array = form(id).get("parts", [])
		if not parts.is_empty(): return str(parts[clampi(index, 0, parts.size() - 1)])
	ensure_loaded()
	return str(choreography.parts[clampi(index, 0, 14)])

static func neutral() -> Array:
	return [0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

static func sample(id: String, mode: String, clip: int, time: float) -> Array:
	var definition: Dictionary = form(id)
	if definition.is_empty():
		# Existing enemy illustrations inherit material pacing without borrowing
		# another creature's joints or changing their authored anatomy/identity.
		var proxy: String = {"spore": "moss", "owl": "volt", "stag": "ignivar"}.get(id, "")
		if not proxy.is_empty():
			# A legacy material proxy is pinned to the shared motion release,
			# never to a replacement presentation of that donor species.
			ensure_loaded()
			definition = data.forms.get(proxy, {})
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

static func socket(id: String, index: int) -> Vector2:
	var anatomy: Dictionary = form(id).get("anatomy", {})
	var point: Array = anatomy.get(part(index, id), anatomy.get("mouth", [0.78, 0.48]))
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
