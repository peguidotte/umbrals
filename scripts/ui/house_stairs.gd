extends RefCounted
## Native depth layers: treads/back rail, actor, then near rail/posts.
const Space = preload("res://scripts/ui/house_space.gd")
const WOOD = Color("74503b")
const EDGE = Color("c69459")
const DARK = Color("352b2a")

static func draw_layer(view: Node2D, foreground: bool) -> void:
	var a: Vector2 = Space.STAIR_BOTTOM
	var b: Vector2 = Space.STAIR_TOP
	if not foreground:
		view.draw_line(a + Vector2(75, -225), b + Vector2(75, -225), DARK, 12, true)
		view.draw_line(a + Vector2(75, -228), b + Vector2(75, -228), EDGE, 5, true)
		for i in range(Space.STEPS + 1):
			var foot: Vector2 = a.lerp(b, float(i) / Space.STEPS)
			if i % 4 == 0: view.draw_line(foot + Vector2(75, -12), foot + Vector2(75, -225), WOOD, 9, true)
			var tread: PackedVector2Array = [foot + Vector2(-29, 0), foot + Vector2(30, 0), foot + Vector2(105, -20), foot + Vector2(46, -20)]
			view.draw_colored_polygon(tread, EDGE)
			view.draw_line(foot + Vector2(-29, 4), foot + Vector2(30, 4), DARK, 8, true)
			view.draw_line(foot + Vector2(-29, 0), foot + Vector2(30, 0), Color("ddb782"), 3, true)
	else:
		# This near rail crosses the waist and legs. It must be drawn AFTER the actor.
		for i in range(0, Space.STEPS + 1, 4):
			var foot: Vector2 = a.lerp(b, float(i) / Space.STEPS) + Vector2(-31, 12)
			view.draw_line(foot, foot + Vector2(0, -225), DARK, 12, true)
			view.draw_line(foot + Vector2(2, 0), foot + Vector2(2, -225), WOOD, 7, true)
		view.draw_line(a + Vector2(-31, 12), b + Vector2(-31, 12), DARK, 16, true)
		view.draw_line(a + Vector2(-31, -213), b + Vector2(-31, -213), DARK, 14, true)
		view.draw_line(a + Vector2(-31, -216), b + Vector2(-31, -216), EDGE, 6, true)
