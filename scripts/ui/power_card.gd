class_name UmbralPowerCard
extends Button
const Assets = preload("res://scripts/assets/catalog.gd")
const Content = preload("res://scripts/content.gd")
const UI = preload("res://scripts/ui/kit.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")
const Rules = preload("res://scripts/rules.gd")
var card: Dictionary = {}
var individual: Dictionary = {}
var effect: Dictionary = {}
var power: Dictionary = {}
var chosen: bool = false
var aiming: bool = false
var home: Vector2 = Vector2.ZERO
var home_rotation: float = 0.0
var reduced_motion: bool = false
var text_scale: float = 1.0
var movement: Tween
var art_texture: Texture2D
var placed: bool = false
var blocked: bool = false
var blocked_caption: String = "INDISPONÍVEL"
var target_caption: String = ""

func _ready() -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]: add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_react)
	mouse_exited.connect(_react)
	focus_entered.connect(_react)
	focus_exited.connect(_react)
	custom_minimum_size = Vector2.ZERO

func configure(data: Dictionary, umbral: Dictionary, team: Array, large: float, reduce: bool) -> void:
	card = data
	individual = umbral
	power = Content.power_stats(str(card.power), int(individual.get("stage", 1)))
	var able_count: int = team.filter(func(member: Dictionary) -> bool: return int(member.get("slot", -1)) >= 0 and int(member.hp) > 0).size()
	effect = Rules.power_effect(card, individual, able_count)
	art_texture = Assets.texture(power.art)
	text_scale = large
	reduced_motion = reduce
	tooltip_text = "%s — %s\n%d ação(ões) · %d potência · %d escudo · %d cura\n%s\nSelecione e clique em uma vaga para mudar o alvo. Q/E: alvo. P: plano. C: detalhes." % [str(power.name).replace("\n", " "), Content.display_name(individual), int(power.cost), int(effect.get("damage", 0)), int(effect.get("block", 0)), int(effect.get("heal", 0)), _scope_label()]
	tooltip_text += "\n" + Content.NATURES[power.nature].name + "\n" + effect_text(effect)
	tooltip_text += "\nExecução: %s · Velocidade %d" % ["prioritária" if int(power.get("priority", 0)) > 0 else "normal", int(individual.get("speed", 0))]
	queue_redraw()

static func effect_text(stats: Dictionary) -> String:
	var lines: Array[String] = []
	if int(stats.get("block", 0)) > 0: lines.append("Escudo absorve dano direto nesta rodada; Queima ignora escudo.")
	for id in stats.get("conditions", {}):
		var definition: Dictionary = Conditions.DEFINITIONS[id]
		lines.append("Aplica %s %d. %s" % [definition.name, int(stats.conditions[id]), definition.description])
	if stats.get("nature", "") == "lightning" and int(stats.damage) > 0: lines.append("Condução: dobra potência se já houver Encharcado; não consome.")
	if stats.get("nature", "") in ["forest", "water", "fire"] and int(stats.damage) > 0: lines.append("Semeado reage: " + {"forest": "Brotação (+6 escudo à fonte)", "water": "Floração (+8 HP à fonte)", "fire": "Incêndio (+4 Queima)"}[stats.nature] + "; consome a semente.")
	if float(stats.get("attack_multiplier", 1.0)) < 1.0: lines.append("Eletrificado: próximo ataque tem −25% potência. Cura e defesa preservadas.")
	return "\n".join(lines)

func _scope_label() -> String:
	return {"single": "Individual", "upper_pair": "Superior + centro", "lower_pair": "Centro + inferior", "all": "Todos"}.get(str(power.get("scope", "single")), "Individual")

func set_chosen(value: bool) -> void:
	chosen = value
	_react()

func place(base: Vector2, angle: float) -> void:
	home = base
	home_rotation = angle
	if not placed:
		position = base
		rotation = angle
		placed = true
	_react()

func _react() -> void:
	if not is_inside_tree(): return
	if is_instance_valid(movement): movement.kill()
	var raised: bool = has_focus() or is_hovered()
	var target: Vector2 = home - Vector2(0, (10 if chosen else 0) + (5 if raised else 0))
	z_index = 6 if raised else 4 if chosen else 0
	if reduced_motion:
		position = target
		scale = Vector2.ONE
		rotation = 0
	else:
		movement = create_tween().set_parallel(true)
		movement.tween_property(self, "position", target, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		movement.tween_property(self, "scale", Vector2.ONE, 0.14)
		movement.tween_property(self, "rotation", 0.0, 0.14)
	queue_redraw()

func _title_size() -> int:
	var point_size: int = int(18 * text_scale)
	for line in str(power.get("name", "")).split("\n"):
		while point_size > 11 and UI.BODY.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, point_size).x > size.x - 12:
			point_size -= 1
	return point_size

func _center_text(value: String, y: float, font_size: int, color: Color) -> void:
	var width: float = UI.BODY.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(UI.BODY, Vector2((size.x - width) * 0.5, y), value, HORIZONTAL_ALIGNMENT_LEFT, size.x - 10, font_size, color)

func title_fits() -> bool:
	for line in str(power.get("name", "")).split("\n"):
		if UI.BODY.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, _title_size()).x > size.x - 10: return false
	return true

func _draw() -> void:
	if card.is_empty(): return
	var color: Color = Color(Content.SPECIES[individual.species].color)
	var contour: PackedVector2Array = PackedVector2Array([Vector2(0, 8), Vector2(8, 0), Vector2(size.x - 8, 0), Vector2(size.x, 8), Vector2(size.x, size.y - 8), Vector2(size.x - 8, size.y), Vector2(8, size.y), Vector2(0, size.y - 8), Vector2(0, 8)])
	draw_colored_polygon(contour, Color("17233b") if chosen else Color("0b1728"))
	draw_polyline(contour, UI.GOLD if chosen else Color("58607d"), 3 if chosen else 2, true)
	if has_focus(): draw_polyline(contour, UI.PAPER, 3, true)
	draw_circle(Vector2(19, 19), 13, Color("242640"))
	draw_string(UI.BODY, Vector2(13, 25), str(power.cost), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UI.PAPER)
	if chosen: draw_string(UI.BODY, Vector2(size.x - 26, 25), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, UI.GOLD)
	if chosen and aiming: draw_line(Vector2(10, 30), Vector2(size.x - 10, 30), UI.GOLD, 2)
	draw_string(UI.BODY, Vector2(38, 24), Content.NATURES[power.nature].name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 45, 12, Color(Content.NATURES[power.nature].color))
	var art_size: float = minf(64, size.x * 0.55)
	draw_texture_rect(art_texture, Rect2(Vector2((size.x - art_size) * 0.5, 33), Vector2.ONE * art_size), false, Color(1, 1, 1, 0.35) if blocked else Color.WHITE)
	var y: float = 111
	var title_size: int = _title_size()
	for line in str(power.name).split("\n"):
		_center_text(line, y, title_size, UI.MUTED if blocked else UI.PAPER)
		y += title_size + 2
	var first: String = "%d poder" % floori(float(effect.damage) * float(effect.get("attack_multiplier", 1.0))) if int(effect.get("damage", 0)) > 0 else "%d escudo" % int(effect.block) if int(effect.get("block", 0)) > 0 else "%d cura" % int(effect.get("heal", 0))
	_center_text(blocked_caption if blocked else first, size.y - 43, mini(14, int(size.x / 8)), UI.FIRE if blocked else color)
	_center_text(target_caption if chosen and not target_caption.is_empty() else _scope_label(), size.y - 25, mini(12, int(size.x / 9)), UI.GOLD if chosen else UI.MUTED)
	_center_text(Content.display_name(individual), size.y - 8, mini(13, int(size.x / 8)), color)
