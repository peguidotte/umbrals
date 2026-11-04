extends RefCounted
## Builds non-battle screens and reports navigation intent to the screen stack.
signal control_created(control: Control, key: String, screen: String)
signal requested(intent: String)
signal starter_requested(species: String)
signal navigation_changed
signal title_navigation
signal title_awakened
const UI = preload("res://scripts/ui/kit.gd")
const Content = preload("res://scripts/content.gd")
const ModalFrame = preload("res://scripts/ui/modal_frame.gd")
const TitleMenu = preload("res://scripts/ui/title_menu.gd")
const JourneyMenu = preload("res://scripts/ui/journey_menu.gd")
const StarterView = preload("res://scripts/ui/starter_view.gd")
const SettingsMenu = preload("res://scripts/ui/settings_menu.gd")
const Codex = preload("res://scripts/ui/codex.gd")
const HelpView = preload("res://scripts/ui/help_view.gd")
const NavigationDialog = preload("res://scripts/ui/navigation_dialog.gd")
const Expedition = preload("res://scripts/expedition/expedition.gd")
var active_view: RefCounted
var _journey_ref: WeakRef
var journey_root: Control:
	get: return _journey_ref.get_ref() if _journey_ref != null else null

func build_modal(screen: String, ui: RefCounted, viewport_size: Vector2, preferences: RefCounted, capture: bool, session: RefCounted, progress: RefCounted, game: RefCounted, screen_root: String) -> Control:
	var menu: bool = screen_root in ["menu", "refuge"]
	var reduced: bool = bool(preferences.values.reduced_motion) or capture
	match screen:
		"journey":
			var checkpoint: Dictionary = {}
			if not session.saved_checkpoint.is_empty():
				var candidate = Expedition.new()
				if candidate.restore(session.saved_checkpoint): checkpoint = candidate.public_state()
			return journey(ui, viewport_size, checkpoint, session.save_notice, reduced)
		"starter": return starter(ui, viewport_size, menu, reduced)
		"confirm_new", "pause", "credits", "confirm_menu": return navigation(screen, ui, viewport_size, menu, reduced, session.expedition_active)
		"settings": return settings(viewport_size, preferences)
		"help": return help(ui, viewport_size, menu, reduced)
		"codex": return codex(viewport_size, progress, preferences.text_scale())
		"victory", "defeat": return ending(ui, viewport_size, game.phase == "victory", game.party, game.total_damage, game.seed_value)
	return null

func title(viewport_size: Vector2, preferences: RefCounted, capture: bool) -> Control:
	var view = TitleMenu.new()
	view.size = viewport_size
	var callbacks: Array[Callable] = [_request.bind("refuge"), _request.bind("codex"), _request.bind("settings"), _request.bind("help"), _request.bind("credits"), _request.bind("quit")]
	view.build(callbacks, _register)
	view.apply_preferences(preferences.values.reduced_motion, capture, preferences.text_scale())
	view.navigation_requested.connect(title_navigation.emit)
	view.card_awakened.connect(title_awakened.emit)
	return view

func journey(ui: RefCounted, viewport_size: Vector2, checkpoint: Dictionary, save_notice: String, reduced: bool) -> Control:
	var view = JourneyMenu.new()
	_journey_ref = weakref(view)
	view.size = viewport_size
	view.z_index = 100
	var callbacks: Array[Callable] = [_request.bind("continue"), _request.bind("new"), _request.bind("practice"), _request.bind("back")]
	view.build(ui, checkpoint, save_notice, callbacks, _register, reduced)
	return view

func starter(ui: RefCounted, viewport_size: Vector2, menu: bool, reduced: bool) -> Control:
	var frame: Dictionary = ModalFrame.create("starter", menu, ui, viewport_size, "Escolha seu primeiro vínculo", "Você começa com um Umbral. Cada um traz três poderes, com duas cópias de cada.", 1150)
	var view = StarterView.new()
	active_view = view
	view.control_created.connect(func(control: Control, key: String): control_created.emit(control, key, "starter"))
	view.starter_requested.connect(starter_requested.emit)
	view.back_requested.connect(func(): requested.emit("back"))
	view.build(frame.body, ui, reduced, menu)
	frame.overlay.tree_exiting.connect(_release_view.bind(view))
	return frame.overlay

func navigation(screen: String, ui: RefCounted, viewport_size: Vector2, menu: bool, reduced: bool, expedition_active: bool) -> Control:
	var view = NavigationDialog.new()
	active_view = view
	view.control_created.connect(func(control: Control, key: String): control_created.emit(control, key, screen))
	view.requested.connect(requested.emit)
	var overlay: Control = view.build(screen, ui, viewport_size, menu, reduced, expedition_active)
	overlay.tree_exiting.connect(_release_view.bind(view))
	return overlay

func settings(viewport_size: Vector2, preferences: RefCounted) -> Control:
	var view = SettingsMenu.new()
	view.size = viewport_size
	view.z_index = 100
	view.build(preferences, _register, _request.bind("back"))
	return view

func codex(viewport_size: Vector2, progress: RefCounted, text_scale: float) -> Control:
	var view = Codex.new()
	view.size = viewport_size
	view.z_index = 100
	view.build(progress, _register, _request.bind("back"), text_scale)
	view.navigation_changed.connect(navigation_changed.emit)
	return view

func help(ui: RefCounted, viewport_size: Vector2, menu: bool, reduced: bool) -> Control:
	var frame: Dictionary = ModalFrame.create("help", menu, ui, viewport_size, "Seu time é o seu grimório.", "Planeje sem gastar; Conjurar confirma a rodada.", 1040)
	var view = HelpView.new()
	active_view = view
	view.control_created.connect(func(control: Control, key: String): control_created.emit(control, key, "help"))
	view.navigation_requested.connect(requested.emit)
	view.build(frame.body, ui, viewport_size, menu, reduced)
	frame.overlay.tree_exiting.connect(_release_view.bind(view))
	return frame.overlay

func ending(ui: RefCounted, viewport_size: Vector2, won: bool, party: Array, damage: int, seed_value: int) -> Control:
	var screen: String = "victory" if won else "defeat"
	var frame: Dictionary = ModalFrame.create(screen, false, ui, viewport_size, "A aurora tem seus nomes." if won else "Ainda existem outros ecos.", "Expedição concluída." if won else "Combine proteção, cura e queimadura para encontrar outro caminho.", 1050)
	var body: VBoxContainer = frame.body
	body.add_child(UI.art(Content.art_binding(party[0]) if won else "characters/stag", Vector2(240, 180)))
	body.add_child(ui.label("%d DANO  ·  %d UMBRALS  ·  SEMENTE %d" % [damage, party.size(), seed_value], 23, UI.GOLD, false, true))
	_button(body, ui, "REVER ÚLTIMA RODADA", "result.history", screen, "history")
	_button(body, ui, "NOVA EXPEDIÇÃO", "result.new", screen, "new_seed", true)
	_button(body, ui, "REPETIR ESTA SEMENTE", "result.retry", screen, "retry")
	_button(body, ui, "VOLTAR AO TÍTULO", "result.menu", screen, "return_menu")
	return frame.overlay

func _button(parent: Control, ui: RefCounted, text: String, key: String, screen: String, intent: String, primary: bool = false) -> void:
	var button: Button = ui.button(text, _request.bind(intent), key, primary)
	parent.add_child(button)
	_register(button, key, screen)

func _request(intent: String) -> void:
	requested.emit(intent)

func _register(control: Control, key: String, screen: String) -> Control:
	control_created.emit(control, key, screen)
	return control

func _release_view(view: RefCounted) -> void:
	if active_view == view: active_view = null
