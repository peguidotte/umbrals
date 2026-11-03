extends RefCounted
## Owns the draw and reserve-zone transition for explicit card collections.
var party: Array
var hand: Array
var deck: Array
var discard_pile: Array
var suspended_cards: Dictionary
var rng: RandomNumberGenerator

func _init(allies: Array, held: Array, draw: Array, discarded: Array, suspended: Dictionary, random: RandomNumberGenerator) -> void:
	party = allies
	hand = held
	deck = draw
	discard_pile = discarded
	suspended_cards = suspended
	rng = random

func _shuffle(cards: Array) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: Variant = cards[i]
		cards[i] = cards[j]
		cards[j] = temp

func draw(capacity: int) -> void:
	while hand.size() < capacity:
		if deck.is_empty():
			if discard_pile.is_empty(): break
			deck = discard_pile.duplicate(true)
			discard_pile.clear()
			_shuffle(deck)
		hand.append(deck.pop_back())

func _sync_owner_zones() -> void:
	var returning: Array = []
	for individual in party:
		var uid: int = int(individual.uid)
		var eligible: bool = int(individual.slot) >= 0 or int(individual.hp) <= 0
		if not eligible:
			if not suspended_cards.has(uid): suspended_cards[uid] = {"deck": [], "discard": [], "entered": true}
			var suspended: Dictionary = suspended_cards[uid]
			_move_owner_cards(deck, suspended.deck, uid)
			_move_owner_cards(discard_pile, suspended.discard, uid)
			_move_owner_cards(hand, suspended.discard, uid)
		elif suspended_cards.has(uid):
			var suspended: Dictionary = suspended_cards[uid]
			var incoming: Array = suspended.deck
			if not bool(suspended.get("entered", true)): _shuffle(incoming)
			returning.append(incoming)
			discard_pile.append_array(suspended.discard)
			suspended_cards.erase(uid)
	if returning.is_empty(): return
	# Recycle only at exhaustion. Otherwise a solo owner's discarded hand
	# would wait behind six new cards and guarantee a reserve-only next hand.
	if deck.is_empty() and not discard_pile.is_empty():
		deck = discard_pile.duplicate(true)
		discard_pile.clear()
		_shuffle(deck)
	for incoming in returning: _interleave_draw(incoming)

func _interleave_draw(incoming: Array) -> void:
	# Uniformly merge the incoming sequence with the current draw sequence.
	# Existing cards retain their relative order; no global redraw or fishing.
	var merged: Array = []
	var old_index: int = 0
	var new_index: int = 0
	while old_index < deck.size() and new_index < incoming.size():
		var old_left: int = deck.size() - old_index
		var new_left: int = incoming.size() - new_index
		if rng.randi_range(1, old_left + new_left) <= old_left:
			merged.append(deck[old_index])
			old_index += 1
		else:
			merged.append(incoming[new_index])
			new_index += 1
	merged.append_array(deck.slice(old_index))
	merged.append_array(incoming.slice(new_index))
	deck = merged

func _move_owner_cards(source: Array, destination: Array, uid: int) -> void:
	for i in range(source.size() - 1, -1, -1):
		if int(source[i].owner) == uid:
			destination.push_front(source[i])
			source.remove_at(i)

