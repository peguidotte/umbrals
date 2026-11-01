class_name UmbralHand
extends Container
## A straight hand preserves the four-zone HUD; wider hands compress without losing cards.
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN: layout_cards()

func layout_cards() -> void:
	var cards: Array = get_children()
	if cards.is_empty(): return
	# Modified hands keep a readable card width and scroll through the same nodes.
	var minimum_width: float = maxf(540, cards.size() * 137.0 - 9.0) if cards.size() > 6 else 540.0
	if custom_minimum_size.x != minimum_width: custom_minimum_size.x = minimum_width
	var gap: float = 9.0
	var width: float = minf(160.0, maxf(56.0, (size.x - gap * (cards.size() - 1)) / cards.size()))
	var height: float = minf(208.0, size.y - 15)
	var spread: float = minf(width + gap, maxf(1.0, (size.x - width) / maxf(1, cards.size() - 1)))
	var total: float = width + spread * (cards.size() - 1)
	for i in range(cards.size()):
		var card: Control = cards[i]
		card.size = Vector2(width, height)
		card.pivot_offset = card.size * 0.5
		card.place(Vector2((size.x - total) * 0.5 + i * spread, 12), 0.0)
		card.queue_redraw()
