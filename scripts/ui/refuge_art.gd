extends RefCounted
## Original provisional vector scenery and human avatar. No external source art.
const Space = preload("res://scripts/ui/refuge_space.gd")
const INK = Color("162d31")
const GOLD = Color("d7b87b")

static func box(c: CanvasItem, rect: Rect2, color: Color, radius: int = 5) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	c.draw_style_box(style, rect)

static func ellipse(c: CanvasItem, center: Vector2, radius: Vector2, color: Color) -> void:
	c.draw_set_transform(center, 0, radius)
	c.draw_circle(Vector2.ZERO, 1, color)
	c.draw_set_transform(Vector2.ZERO)

static func plant(c: CanvasItem, at: Vector2, scale: float = 1.0) -> void:
	ellipse(c, at + Vector2(0, 6), Vector2(25, 8) * scale, Color(0, 0, 0, 0.2))
	box(c, Rect2(at - Vector2(17, 26) * scale, Vector2(34, 30) * scale), Color("bd8565"))
	for i in range(5):
		var tip: Vector2 = at + Vector2((i - 2) * 15, -52 - (2 - absi(i - 2)) * 14) * scale
		c.draw_line(at - Vector2(0, 24) * scale, tip, Color("547c5c"), 4 * scale)
		ellipse(c, tip, Vector2(14, 8) * scale, Color("739a77") if i % 2 == 0 else Color("436e63"))

static func background(c: CanvasItem) -> void:
	box(c, Rect2(72, 117, 1056, 520), Color("0b2027"), 20)
	box(c, Rect2(90, 125, 1020, 180), Color("34575b"), 12)
	c.draw_rect(Rect2(104, 265, 992, 345), Color("9d856b"))
	for i in range(9):
		var y: float = 270 + i * 39
		c.draw_line(Vector2(104, y), Vector2(1096, y), Color("796d5b"), 2)
		for j in range(6):
			var x: float = 140 + j * 185 + (85 if i % 2 == 0 else 0)
			if x > 1096: continue
			c.draw_line(Vector2(x, y), Vector2(x, minf(610, y + 38)), Color("86755f"), 1)
	c.draw_rect(Rect2(104, 256, 992, 14), Color("203e42"))
	# Broad modern window: forest silhouettes, no borrowed layout or pixels.
	box(c, Rect2(440, 145, 280, 108), Color("a8bcb4"))
	c.draw_rect(Rect2(449, 154, 262, 90), Color("193e4c"))
	c.draw_circle(Vector2(657, 177), 16, Color("e5dfb7"))
	for i in range(10):
		var x: float = 458 + i * 27
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 19, 244), Vector2(x, 173 + (i % 3) * 15), Vector2(x + 22, 244)]), Color("28595b"))
	c.draw_line(Vector2(580, 154), Vector2(580, 244), Color("a8bcb4"), 7)
	box(c, Rect2(970, 145, 116, 142), Color("172e34"))
	box(c, Rect2(980, 155, 96, 132), Color("426969"))
	c.draw_rect(Rect2(992, 168, 72, 87), Color("203f4b"))
	c.draw_line(Vector2(1062, 230), Vector2(1062, 251), GOLD, 4)
	box(c, Rect2(984, 281, 90, 18), Color("d0b487"))
	# Warm lamplight and woven rug define an uncluttered central path.
	ellipse(c, Vector2(580, 416), Vector2(285, 160), Color(0.95, 0.8, 0.47, 0.06))
	box(c, Rect2(455, 355, 290, 195), Color("4b7272"), 12)
	c.draw_rect(Rect2(467, 367, 266, 171), Color("94ada0"), false, 2)
	for i in range(8):
		c.draw_line(Vector2(475 + i * 35, 376), Vector2(475 + i * 35, 530), Color(0.7, 0.8, 0.7, 0.09), 2)
	for r in [Space.OBSTACLES[0], Space.OBSTACLES[1]]:
		box(c, Rect2(r.position + Vector2(0, 15), r.size), Color("3c4440"))
		box(c, Rect2(r.position - Vector2(0, 17), r.size), Color("b19470"))
		c.draw_line(r.position + Vector2(12, 68), r.position + Vector2(r.size.x - 12, 68), Color("d3b68d"), 3)
	# Open paper book and electric desk lamp.
	c.draw_colored_polygon(PackedVector2Array([Vector2(260, 282), Vector2(303, 290), Vector2(303, 330), Vector2(260, 322)]), Color("e9dcb5"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(305, 290), Vector2(350, 281), Vector2(350, 322), Vector2(305, 330)]), Color("d6c99f"))
	for i in range(4): c.draw_line(Vector2(268, 293 + i * 7), Vector2(295, 299 + i * 7), Color("8e9073"), 1)
	c.draw_line(Vector2(214, 288), Vector2(214, 235), GOLD, 5)
	box(c, Rect2(193, 226, 43, 18), Color("e4c985"))
	ellipse(c, Vector2(214, 288), Vector2(20, 6), GOLD)
	# Covered workbench: no shop symbols or fake upgrade inventory.
	box(c, Rect2(785, 273, 154, 56), Color("718c88"))
	c.draw_line(Vector2(807, 278), Vector2(807, 328), Color("a4b4a5"), 3)
	c.draw_line(Vector2(907, 278), Vector2(907, 328), Color("a4b4a5"), 3)
	box(c, Space.OBSTACLES[2], Color("355659"), 16)
	box(c, Rect2(180, 465, 235, 32), Color("64827a"), 12)
	for i in range(2): box(c, Rect2(194 + i * 103, 499, 96, 48), Color("75958a"), 9)
	box(c, Rect2(192, 482, 20, 70), Color("52746e"), 8)
	box(c, Rect2(384, 482, 20, 70), Color("52746e"), 8)
	box(c, Space.OBSTACLES[3], Color("615947"), 12)
	box(c, Rect2(800, 478, 160, 56), Color("b39671"), 12)
	ellipse(c, Vector2(860, 502), Vector2(12, 7), Color("e5dbc1"))
	plant(c, Vector2(139, 292), 0.8)
	plant(c, Vector2(1062, 558), 1.1)
	c.draw_line(Vector2(104, 613), Vector2(1096, 613), GOLD, 3)

static func avatar(c: CanvasItem, point: Vector2, facing: Vector2, stride: float) -> void:
	ellipse(c, point + Vector2(0, 2), Vector2(23, 8), Color(0.02, 0.07, 0.08, 0.35))
	var swing: float = sin(stride) * 5
	# Sneakers, trousers, contemporary jacket and small shoulder bag.
	box(c, Rect2(point + Vector2(-13, -23 + swing), Vector2(10, 24)), Color("263d4c"), 3)
	box(c, Rect2(point + Vector2(3, -23 - swing), Vector2(10, 24)), Color("263d4c"), 3)
	box(c, Rect2(point + Vector2(-15, -5 + swing), Vector2(14, 7)), Color("e1d9be"), 3)
	box(c, Rect2(point + Vector2(2, -5 - swing), Vector2(14, 7)), Color("e1d9be"), 3)
	box(c, Rect2(point + Vector2(-16, -50), Vector2(32, 32)), Color("cf9a55"), 7)
	c.draw_line(point + Vector2(-17, -43), point + Vector2(-21, -24 - swing), Color("e5b48e"), 7)
	c.draw_line(point + Vector2(17, -43), point + Vector2(21, -24 + swing), Color("e5b48e"), 7)
	c.draw_circle(point + Vector2(0, -61), 14, Color("e5b48e"))
	c.draw_arc(point + Vector2(0, -63), 13, PI, TAU, 16, Color("334344"), 9)
	if facing.y < -0.5:
		c.draw_circle(point + Vector2(0, -63), 12, Color("334344"))
		box(c, Rect2(point + Vector2(-10, -46), Vector2(20, 23)), Color("536d64"), 4)
	else:
		var offset: float = facing.x * 4
		c.draw_circle(point + Vector2(-5 + offset, -60), 1.6, INK)
		c.draw_circle(point + Vector2(5 + offset, -60), 1.6, INK)
		c.draw_line(point + Vector2(-11, -48), point + Vector2(12, -25), INK, 3)
		box(c, Rect2(point + Vector2(9, -34), Vector2(12, 15)), Color("536d64"), 3)
