extends RefCounted
## Confirmation and navigation overlays emit destinations; the screen stack
## decides what those destinations do.
signal control_created(control: Control, key: String)
signal requested(intent: String)
const UI = preload("res://scripts/ui/kit.gd")
const ModalFrame = preload("res://scripts/ui/modal_frame.gd")
const TitleButton = preload("res://scripts/ui/title_button.gd")

func build(screen: String, ui: RefCounted, viewport_size: Vector2, menu: bool, reduced_motion: bool, expedition_active: bool) -> Control:
	var title: String = ""
	var subtitle: String = ""
	var width: float = 850
	match screen:
		"confirm_new":
			title = "Começar uma nova expedição?"
			subtitle = "A expedição salva será substituída ao escolher o primeiro vínculo. Voltar mantém o progresso atual."
		"pause":
			title = "O bosque espera."
			subtitle = "Sua expedição está em pausa."
			width = 650
		"credits": title = "Feito para despertar ecos."
		"confirm_menu":
			title = "Voltar ao título?"
			subtitle = "A expedição será retomada no último estado confirmado. Comandos ainda não conjurados serão desfeitos." if expedition_active else "O treino atual será encerrado. A expedição salva fica preservada."
			width = 760
	var frame: Dictionary = ModalFrame.create(screen, menu, ui, viewport_size, title, subtitle, width)
	var body: VBoxContainer = frame.body
	match screen:
		"confirm_new":
			_button(body, ui, menu, reduced_motion, "MANTER A EXPEDIÇÃO SALVA", "new.cancel", "back", true)
			_button(body, ui, menu, reduced_motion, "ESCOLHER NOVO VÍNCULO", "new.confirm", "confirm_new")
		"pause":
			_button(body, ui, menu, reduced_motion, "CONTINUAR", "pause.resume", "back", true)
			_button(body, ui, menu, reduced_motion, "GRIMÓRIO", "pause.codex", "codex")
			_button(body, ui, menu, reduced_motion, "OPÇÕES", "pause.settings", "settings")
			_button(body, ui, menu, reduced_motion, "COMO JOGAR", "pause.help", "help")
			_button(body, ui, menu, reduced_motion, "VOLTAR AO TÍTULO", "pause.menu", "confirm_menu")
		"credits":
			body.add_child(ui.paragraph("Umbral\nCriaturas e poderes: arte vetorial original.\nCenário: criado com Image Gen para este projeto.\nÁudio: síntese original, sem samples externos.\nFontes: DejaVu Sans e DejaVu Serif.", 24, UI.PAPER))
			_button(body, ui, menu, reduced_motion, "VOLTAR", "credits.back", "back", true)
		"confirm_menu":
			_button(body, ui, menu, reduced_motion, "CONTINUAR NO BOSQUE", "confirm.cancel", "back", true)
			_button(body, ui, menu, reduced_motion, "VOLTAR AO TÍTULO", "confirm.yes", "return_menu")
	return frame.overlay

func _button(parent: Control, ui: RefCounted, menu: bool, reduced_motion: bool, text: String, key: String, intent: String, primary: bool = false) -> void:
	var button: Button
	if menu:
		button = TitleButton.new()
		button.text = text
		button.primary = primary
		button.reduced_motion = reduced_motion
		button.custom_minimum_size.y = 56
		button.pressed.connect(func(): requested.emit(intent))
	else: button = ui.button(text, func(): requested.emit(intent), key, primary)
	parent.add_child(button)
	control_created.emit(button, key)
