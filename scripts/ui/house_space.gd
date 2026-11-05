extends RefCounted
## One continuous home. Coordinates never reset at room boundaries.
const SIZE = Vector2(4200, 2145)
const VIEW = Vector2(1600, 900)
const FLOOR_Y = 1730.0
const UPPER_Y = 742.0
const SPEED = 330.0
const LEFT = 320.0
const RIGHT = 3880.0
const EXIT = 3840.0
const UPPER_LEFT = 320.0
const UPPER_RIGHT = 2250.0
const SPAWN = Vector2(650, FLOOR_Y)
const BED = Vector2(650, 1450)
const STAIR_BOTTOM = Vector2(3140, FLOOR_Y)
const STAIR_TOP = Vector2(2250, UPPER_Y)
const STEPS = 20
const TITLES = {"bedroom": "Casa de Pietro · Quarto", "living": "Casa de Pietro · Sala", "kitchen": "Casa de Pietro · Cozinha", "mother": "Andar de cima · Quarto da mãe"}
const NAMES = {"stairs": "Escada", "codex": "Grimório", "improvements": "Bancada", "exit": "Saída para preparar expedição"}
const OBJECTS = {"codex": Rect2(1020, 1230, 250, 345), "improvements": Rect2(2280, 1320, 395, 275), "exit": Rect2(3860, 995, 220, 570)}

static func zone(point: Vector2, upper: bool) -> String:
	if upper: return "mother"
	if point.x < 900: return "bedroom"
	return "living" if point.x < 2850 else "kitchen"

static func walk(point: Vector2, direction: Vector2, delta: float, upper: bool = false) -> Vector2:
	var bounds = Vector2(UPPER_LEFT, UPPER_RIGHT) if upper else Vector2(LEFT, RIGHT)
	return Vector2(clampf(point.x + direction.x * SPEED * minf(delta, 0.1), bounds.x, bounds.y), UPPER_Y if upper else FLOOR_Y)

static func station(identity: String, upper: bool = false) -> float:
	if identity == "stairs": return STAIR_TOP.x if upper else STAIR_BOTTOM.x
	if identity == "codex": return 1145
	if identity == "improvements": return 2480
	return EXIT + 20

static func nearest(point: Vector2, upper: bool, stairs: bool = false) -> String:
	if stairs: return "stairs"
	if absf(point.x - station("stairs", upper)) < 72: return "stairs"
	if upper: return ""
	for identity in OBJECTS:
		if absf(point.x - station(identity)) < 80: return identity
	return ""

static func object_rect(identity: String, upper: bool, stairs: bool, point: Vector2) -> Rect2:
	if identity == "stairs":
		var anchor: Vector2 = point if stairs else (STAIR_TOP if upper else STAIR_BOTTOM)
		return Rect2(anchor - Vector2(90, 140), Vector2(180, 160))
	return OBJECTS.get(identity, Rect2()) if not upper and not stairs else Rect2()

static func stair_point(progress: float) -> Vector2:
	# Feet rest on each real tread; a brief lift joins the next tread continuously.
	var phase: float = clampf(progress, 0, 1) * STEPS
	var step_index: float = floorf(phase)
	var lift: float = smoothstep(0.55, 1.0, fmod(phase, 1.0))
	return Vector2(lerpf(STAIR_BOTTOM.x, STAIR_TOP.x, progress), lerpf(STAIR_BOTTOM.y, STAIR_TOP.y, (step_index + lift) / STEPS))
