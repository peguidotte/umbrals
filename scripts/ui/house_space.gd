extends RefCounted
## Geometry and adjacency of Pietro's initial home; never the portable shelter.
const Legacy = preload("res://scripts/ui/refuge_space.gd")
const SIZE = Legacy.SIZE
const FLOOR_Y = Legacy.FLOOR_Y
const SPEED = Legacy.SPEED
const LEFT = Legacy.LEFT
const RIGHT = Legacy.RIGHT
const EXIT = Legacy.EXIT
const SPAWN = Vector2(570, FLOOR_Y)
const STAIR_BOTTOM = Vector2(695, FLOOR_Y)
const STAIR_TOP = Vector2(225, 245)
const BED = Vector2(565, 620)
const TITLES = {"bedroom": "Casa de Pietro · Quarto", "living": "Casa de Pietro · Sala", "kitchen": "Casa de Pietro · Cozinha", "mother": "Andar de cima · Quarto da mãe"}
const OBJECTS = {
	"bedroom": {"living": Rect2(1440, 300, 205, 430)},
	"living": {"bedroom": Rect2(8, 390, 150, 350), "codex": Rect2(160, 510, 240, 160), "improvements": Rect2(990, 440, 310, 230), "kitchen": Rect2(1255, 300, 140, 370), "exit": Rect2(1455, 300, 190, 420)},
	"kitchen": {"living": Rect2(0, 310, 170, 420), "stairs": Rect2(270, 190, 460, 520)},
	"mother": {"stairs": Rect2(1310, 470, 330, 265)}
}
const NAMES = {"living": "Sala", "bedroom": "Quarto de Pietro", "kitchen": "Cozinha", "stairs": "Escada", "codex": "Grimório", "improvements": "Bancada", "exit": "Saída para preparar expedição"}

static func walk(point: Vector2, direction: Vector2, delta: float) -> Vector2:
	return Legacy.walk(point, direction, delta)

static func station(room: String, identity: String) -> float:
	if identity == "codex": return 270
	if identity == "improvements": return 1170
	if identity == "kitchen": return 1330
	if identity == "bedroom": return LEFT
	if identity == "stairs": return STAIR_BOTTOM.x if room == "kitchen" else 1430.0
	if identity == "living": return EXIT if room == "bedroom" else LEFT
	return EXIT + 25

static func nearest(room: String, point: Vector2) -> String:
	if not is_equal_approx(point.y, FLOOR_Y): return "stairs"
	for identity in OBJECTS[room]:
		if absf(point.x - station(room, identity)) < (65 if identity in ["kitchen", "exit"] else 100): return identity
	return ""

static func threshold(room: String, previous: Vector2, point: Vector2) -> String:
	if previous.is_equal_approx(point): return ""
	if room == "bedroom" and point.x >= EXIT: return "living"
	if room in ["living", "kitchen"] and point.x <= LEFT: return "bedroom" if room == "living" else "living"
	if room == "living" and point.x >= EXIT: return "journey"
	return ""

static func destination(room: String, identity: String) -> Dictionary:
	if identity == "living": return {"room": "living", "x": 160.0 if room == "bedroom" else 1330.0}
	if identity == "bedroom": return {"room": "bedroom", "x": 1430.0}
	if identity == "kitchen": return {"room": "kitchen", "x": 180.0}
	return {}
