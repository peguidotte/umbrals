extends RefCounted
## Owns stack transitions, screen visibility, focus restoration and modal lifetime.
## Screen builders provide their new roots synchronously in response to requests.
signal map_requested
signal modal_requested(screen: String)
signal debug_requested
signal phase_requested
const Codex = preload("res://scripts/ui/codex.gd")
const ModalFrame = preload("res://scripts/ui/modal_frame.gd")
var screens: RefCounted
var focus_registry: RefCounted
var world: Control
var audio: Node
var preferences: RefCounted
var viewport: Viewport
var cards: Array
var visual_capture: bool = false
var menu_root: Control
var battle_root: Control
var map_root: Control
var modal_root: Control
var title_entrance: Tween

func configure(stack: RefCounted, focus: RefCounted, world_view: Control, sound: Node, settings: RefCounted, screen_viewport: Viewport, card_nodes: Array, capture: bool) -> void:
	screens = stack
	focus_registry = focus
	world = world_view
	audio = sound
	preferences = settings
	viewport = screen_viewport
	cards = card_nodes
	visual_capture = capture

func remember_focus() -> void:
	focus_registry.remember(screens.top(), viewport.gui_get_focus_owner())

func push(screen: String) -> void:
	remember_focus()
	screens.push(screen)

func pop() -> void:
	if screens.top() == "codex" and is_instance_valid(modal_root) and modal_root is Codex:
		if modal_root.go_back(): return
	remember_focus()
	screens.pop()

func set_group(screen: String) -> void:
	focus_registry.set_group(screen)

func focus(key: String, screen: String) -> void:
	focus_registry.restore(key, screen, cards)
	debug_requested.emit()

func refresh() -> void:
	if is_instance_valid(title_entrance): title_entrance.kill()
	menu_root.modulate = Color.WHITE
	var battle: bool = screens.root() == "battle"
	world.title_mode = not battle
	world.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if not battle else CanvasItem.TEXTURE_FILTER_NEAREST
	world.queue_redraw()
	menu_root.visible = screens.root() == "menu"
	menu_root.input_active = screens.top() == "menu"
	if is_instance_valid(map_root): map_root.visible = screens.root() == "map"
	if is_instance_valid(battle_root):
		battle_root.visible = battle
		battle_root.pause_feedback(screens.top() != "battle")
	if is_instance_valid(modal_root):
		# Hide immediately, free after the pressed control's input event completes.
		modal_root.hide()
		modal_root.queue_free()
	modal_root = null
	if screens.top() == "map": map_requested.emit()
	elif screens.top() not in ["menu", "battle"]: modal_requested.emit(screens.top())
	set_group(screens.top())
	focus(focus_registry.memory.get(screens.top(), ""), screens.top())
	if screens.root() == "menu":
		audio.set_title(true)
		var arriving: Control = menu_root if screens.top() == "menu" else modal_root
		if is_instance_valid(arriving):
			arriving.modulate = Color.WHITE
			if not preferences.values.reduced_motion and not visual_capture:
				title_entrance = ModalFrame.fade_in(arriving)
	else: audio.set_title(false)
	debug_requested.emit()
	phase_requested.emit()

func suppress_motion() -> void:
	if is_instance_valid(title_entrance): title_entrance.kill()
	if is_instance_valid(menu_root): menu_root.modulate = Color.WHITE
	if is_instance_valid(modal_root): modal_root.modulate = Color.WHITE
