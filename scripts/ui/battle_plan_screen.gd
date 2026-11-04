extends RefCounted
## Complete plan overlay. It receives the player's visible plan and emits intents;
## it has no access to the private enemy plan or command execution.
signal control_created(control: Control, key: String)
signal remove_requested(kind: String, id: int)
signal target_requested(index: int, slot: int)
signal inspect_requested(index: int)
signal back_requested
signal clear_requested
signal cast_requested

const UI = preload("res://scripts/ui/kit.gd")
const ModalFrame = preload("res://scripts/ui/modal_frame.gd")
const BattlePlan = preload("res://scripts/ui/battle_plan.gd")

func build(ui: RefCounted, viewport_size: Vector2, score: Dictionary, action_budget: int, entries: Array, hand: Array, party: Array, enemies: Array, text_scale: float) -> Control:
	var subtitle: String = "%d de %d ações · Trocas e itens primeiro, depois prioridade e velocidade." % [int(score.actions), action_budget]
	var frame: Dictionary = ModalFrame.create("plan", false, ui, viewport_size, "Plano da rodada", subtitle, 1200)
	var body: VBoxContainer = frame.body
	var plan = BattlePlan.new()
	body.add_child(plan)
	plan.control_created.connect(control_created.emit)
	plan.remove_requested.connect(remove_requested.emit)
	plan.target_requested.connect(target_requested.emit)
	plan.inspect_requested.connect(inspect_requested.emit)
	plan.populate(entries, hand, party, enemies, text_scale)
	body.add_child(ui.paragraph("Só os seus comandos. Inimigos intercalam ações por velocidade; empates entre donos são sorteados ao Conjurar. Defesa, estados e nocautes podem mudar o resultado.", 18))
	var controls: HBoxContainer = UI.row(12)
	body.add_child(controls)
	_button(controls, ui, "VOLTAR AO CAMPO", "plan.back", back_requested.emit, true)
	var clear: Button = _button(controls, ui, "LIMPAR PLANO", "plan.clear", clear_requested.emit)
	clear.disabled = entries.is_empty()
	var commit: Button = _button(controls, ui, "CONJURAR PLANO", "plan.cast", cast_requested.emit, true)
	commit.disabled = not score.valid
	if not score.valid and not entries.is_empty(): body.add_child(ui.paragraph(str(score.reason), 20, UI.FIRE))
	return frame.overlay

func _button(parent: Control, ui: RefCounted, text: String, key: String, intent: Callable, primary: bool = false) -> Button:
	var button: Button = ui.button(text, intent, key, primary)
	parent.add_child(button)
	control_created.emit(button, key)
	return button
