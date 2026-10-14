class_name UmbralHand
extends Container
## A dimension-driven fan is the deliberate layout model for cards, not a fixed screen grid.
func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN: return
	layout_cards()

func layout_cards() -> void:
	var cards: Array = get_children()
	var spread: float = minf(150, (size.x - 200) / maxf(1, cards.size() - 1))
	for i in range(cards.size()):
		var card: Control = cards[i]
		card.size = Vector2(180, 244)
		var offset: float = i - (cards.size() - 1) / 2.0
		var base = Vector2(size.x * 0.5 + offset * spread - 90, 23 + absf(offset) * 9)
		card.place(base, deg_to_rad(offset * 2.2))
