class_name UmbralHand
extends Container
## The painted pilot fans the actual buttons. Modified hands retain their scroll path.
var painted: bool = false
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN: layout_cards()

func layout_cards() -> void:
	var cards: Array = get_children()
	cards.sort_custom(func(a: Control, b: Control) -> bool: return a.hand_order < b.hand_order)
	if cards.is_empty(): return
	var fan: bool = painted and cards.size() <= 6
	if get_parent() is ScrollContainer: get_parent().clip_contents = not fan
	if fan:
		if custom_minimum_size.x != 540: custom_minimum_size.x = 540
		var width: float = minf(225, (size.x - 48) / (1 + .63 * maxi(1, cards.size() - 1)))
		var height: float = width * 1.5
		var spread: float = minf(width * .78, (size.x - 48 - width) / maxi(1, cards.size() - 1))
		var total: float = width + spread * (cards.size() - 1)
		for i in range(cards.size()):
			var card: Control = cards[i]
			var curve: float = (i - (cards.size() - 1) * .5) / maxf(1, (cards.size() - 1) * .5)
			card.fanned = true
			card.size = Vector2(width, height)
			card.pivot_offset = card.size * .5
			card.place(Vector2((size.x - total) * .5 + i * spread, size.y - height - 22 + curve * curve * 17), curve * .13)
		return
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
		card.fanned = false
		card.size = Vector2(width, height)
		card.pivot_offset = card.size * 0.5
		card.place(Vector2((size.x - total) * 0.5 + i * spread, 12), 0.0)
		card.queue_redraw()

func sync_layers() -> void:
	# Godot GUI picking follows sibling order, independently of CanvasItem Z.
	# Keep both orders aligned without changing canonical hand/card indices.
	var ordered: Array = get_children()
	ordered.sort_custom(func(a: Control, b: Control) -> bool: return a.z_index < b.z_index if a.z_index != b.z_index else a.hand_order < b.hand_order)
	for i in ordered.size():
		if ordered[i].get_index() != i: move_child(ordered[i], i)

func present(index: int) -> void:
	# Hover may change the targeting intent, but never move another card under
	# an imminent click. Selection and actual keyboard/controller focus lift it.
	for card: Control in get_children():
		var prominent: bool = card.hand_order == index and card.chosen
		if card.fan_prominent != prominent:
			card.fan_prominent = prominent
			card._react()
