extends RefCounted
## Resolved history and pile contents; draw order is deliberately not shown.
const UI = preload("res://scripts/ui/kit.gd")
const Content = preload("res://scripts/content.gd")
const BattleReadout = preload("res://scripts/ui/battle_readout.gd")
signal back_requested
var ui = UI.new()
var register: Callable

func _button(parent: Node, text: String, action: Callable, key: String, screen: String, primary: bool = false) -> Button:
	var button: Button = ui.button(text, action, key, primary)
	parent.add_child(button)
	register.call(button, key, screen)
	return button

func pile(body: VBoxContainer, source: Array, owners: Dictionary, registry: Callable) -> void:
	register = registry
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 300
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var list: VBoxContainer = UI.column(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var grouped: Dictionary = {}
	for card in source:
		var key: String = "%s:%s" % [card.owner, card.power]
		if not grouped.has(key): grouped[key] = {"card": card, "count": 0}
		grouped[key].count += 1
	var keys: Array = grouped.keys()
	keys.sort()
	for key in keys:
		var group: Dictionary = grouped[key]
		var owner: Dictionary = owners.get(int(group.card.owner), {})
		list.add_child(ui.label("%d×  %s · %s%s" % [int(group.count), str(Content.POWERS[group.card.power].name).replace("\n", " "), Content.display_name(owner), " · INCAPACITADO" if int(owner.hp) <= 0 else ""], 23, UI.MUTED if int(owner.hp) <= 0 else UI.PAPER))
	if source.is_empty(): list.add_child(ui.paragraph("Esta pilha está vazia.", 23))
	body.add_child(ui.paragraph("Cartas usadas e não usadas vão ao descarte no fim da rodada. O descarte só é embaralhado quando a compra acaba. Reservas aptas ficam fora do ciclo.", 19))
	_button(body, "VOLTAR", back_requested.emit, "pile.back", "pile", true)



func history(body: VBoxContainer, result: Dictionary, viewport_size: Vector2, registry: Callable) -> void:
	register = registry
	body.add_child(ui.label("%d HP retirado dos inimigos · %d HP perdido pelo time" % [int(result.get("applied_damage", 0)), int(result.get("incoming", 0))], 22, UI.GOLD))
	if bool(result.get("passed", false)): body.add_child(ui.paragraph("Você resorteou: nenhuma ação aliada foi executada. Os inimigos agiram normalmente.", 20))
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(390, viewport_size.y - 370)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode = Control.FOCUS_ALL
	body.add_child(scroll)
	var list: VBoxContainer = UI.column(12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var number: int = 0
	for event in result.get("events", []):
		var text: String = BattleReadout.event_line(event)
		if text.is_empty(): continue
		number += 1
		list.add_child(ui.paragraph("%d. %s" % [number, text], 21, UI.FIRE if event.actor_side == "enemy" else UI.PAPER))
	_button(body, "VOLTAR", back_requested.emit, "history.back", "history", true)
	register.call(scroll, "history.content", "history")


