extends RefCounted
## Owns committed turn lifecycle and its cancellation token. The scene responds
## to semantic signals for rendering, persistence, focus and telemetry.
signal selection_changed
signal battle_changed(animated: bool)
signal checkpoint_requested
signal result_requested
signal phase_requested
signal focus_requested
signal text_scale_requested
signal debug_requested
signal logged(event_name: String, details: Dictionary)

var game: RefCounted
var screens: RefCounted
var audio: Node
var resolve: Callable
var busy: bool = false
var epoch: int = 0
var targeting_index: int = -1
var buffered_card: int = -1
var buffered_at: int = 0
var rejected_busy_casts: int = 0
var last_card_index: int = 0

func configure(next_game: RefCounted, screen_stack: RefCounted, sound: Node, play_resolution: Callable) -> void:
	game = next_game
	screens = screen_stack
	audio = sound
	resolve = play_resolution

func cancel() -> void:
	epoch += 1
	busy = false

func aim_card(index: int) -> void:
	if busy or screens.top() != "battle" or not index in game.selected or targeting_index == index: return
	targeting_index = index
	selection_changed.emit()

func select(index: int) -> void:
	if screens.top() != "battle": return
	if busy:
		buffered_card = index
		buffered_at = Time.get_ticks_msec()
		return
	if game.toggle(index):
		targeting_index = index
		last_card_index = index
		audio.play("select", true)
		selection_changed.emit()

func cast() -> void:
	if screens.top() != "battle": return
	if busy:
		rejected_busy_casts += 1
		debug_requested.emit()
		return
	if not game.preview().valid: return
	busy = true
	var token: int = epoch
	var result: Dictionary = game.play()
	if not result.get("ok", false):
		busy = false
		selection_changed.emit()
		return
	if game.phase in ["victory", "defeat"]: result_requested.emit()
	checkpoint_requested.emit()
	selection_changed.emit()
	await resolve.call(result, token)
	if token != epoch: return
	busy = false
	text_scale_requested.emit()
	targeting_index = -1
	battle_changed.emit(true)
	phase_requested.emit()
	if screens.top() == "battle": focus_requested.emit()
	logged.emit("powers_cast", {"damage": result.get("applied_damage", 0), "phase": game.phase})
	buffered_card = -1
	debug_requested.emit()

func redraw() -> void:
	if busy or screens.top() != "battle": return
	busy = true
	var token: int = epoch
	if not game.redraw():
		busy = false
		selection_changed.emit()
		return
	audio.play("draw", true)
	checkpoint_requested.emit()
	selection_changed.emit()
	await resolve.call(game.last_result, token)
	if token != epoch: return
	busy = false
	if game.phase in ["victory", "defeat"]: result_requested.emit()
	text_scale_requested.emit()
	targeting_index = -1
	battle_changed.emit(false)
	phase_requested.emit()
	if screens.top() == "battle": focus_requested.emit()
	logged.emit("hand_redrawn", {"round": game.round_number})

func cycle_target(direction: int) -> void:
	if busy or not targeting_index in game.selected: return
	var options: Array[int] = game.target_options(targeting_index)
	if options.size() < 2: return
	var current: int = options.find(int(game.hand[targeting_index].get("target_slot", -1)))
	if game.set_target(targeting_index, options[posmod(current + direction, options.size())]): audio.play("select", true)
