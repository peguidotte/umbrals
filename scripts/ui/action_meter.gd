extends Label
## Public action budget supplied by the HUD coordinator, never polled from rules.
const UI = preload("res://scripts/ui/kit.gd")
var capacity: int = 3
var spent: int = 0

func configure(budget: int, planned: int) -> void:
	capacity = maxi(0, budget)
	spent = maxi(0, planned)
	var remaining: int = maxi(0, capacity - spent)
	text = "%d %s · %d/%d no plano" % [remaining, "livre" if remaining == 1 else "livres", spent, capacity]
	if spent > capacity: text = "%d %s em excesso" % [spent - capacity, "ação" if spent - capacity == 1 else "ações"]
	queue_redraw()

func _draw() -> void:
	var count: int = mini(capacity, 8)
	var step: float = 20.0
	var start: float = (size.x - (count - 1) * step) * 0.5
	for i in range(count):
		var center := Vector2(start + i * step, 9)
		var gem := PackedVector2Array([center + Vector2(0, -7), center + Vector2(7, 0), center + Vector2(0, 7), center + Vector2(-7, 0), center + Vector2(0, -7)])
		draw_colored_polygon(gem, UI.RAISED if i < spent else UI.GOLD)
		draw_polyline(gem, UI.BORDER if i < spent else UI.PAPER, 1)
		if i < spent: draw_line(center + Vector2(-3, 3), center + Vector2(3, -3), UI.MUTED, 1)
