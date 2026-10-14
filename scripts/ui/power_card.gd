class_name UmbralPowerCard
extends Button
const Content = preload("res://scripts/content.gd")
const Rules = preload("res://scripts/rules.gd")
const UI = preload("res://scripts/ui/kit.gd")
var card: Dictionary = {}
var individual: Dictionary = {}
var effect: Dictionary = {}
var power: Dictionary = {}
var chosen: bool = false
var home: Vector2 = Vector2.ZERO
var home_rotation: float = 0.0
var reduced_motion: bool = false
var text_scale: float = 1.0
var movement: Tween
var art_texture: Texture2D
var placed: bool = false

func _ready() -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]: add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_react)
	mouse_exited.connect(_react)
	focus_entered.connect(_react)
	focus_exited.connect(_react)
	custom_minimum_size = Vector2(180, 244)
	pivot_offset = custom_minimum_size * 0.5

func configure(data: Dictionary, umbral: Dictionary, team: Array, large: float, reduce: bool) -> void:
	card = data
	individual = umbral
	power = Content.power_stats(card.power, int(individual.stage))
	effect = Rules.evaluate([card], team)
	art_texture = load("res://assets/powers/%s.svg" % power.art)
	text_scale = large
	reduced_motion = reduce
	tooltip_text = "%s — %s\n%d dano · %d escudo · %d cura\nTrait: %s\nPassiva: %s\nC: inspeção detalhada" % [power.name.replace("\n", " "), Content.display_name(individual), effect.damage, effect.block, effect.heal, Content.trait_text(individual), Content.PASSIVES[individual.passive].description]
	queue_redraw()

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
	var target: Vector2 = home - Vector2(0, 28 if chosen else 0) - Vector2(0, 18 if raised else 0)
	var target_scale: Vector2 = Vector2.ONE * (1.035 if raised and not reduced_motion else 1.0)
	z_index = 6 if raised else 4 if chosen else 0
	if reduced_motion:
		position = target
		scale = target_scale
		rotation = 0 if raised else home_rotation
	else:
		movement = create_tween().set_parallel(true)
		movement.tween_property(self, "position", target, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		movement.tween_property(self, "scale", target_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		movement.tween_property(self, "rotation", 0.0 if raised else home_rotation, 0.16)
	queue_redraw()

func _center_text(text: String, y: float, font_size: int, color: Color, display: bool = false) -> void:
	var font: Font = UI.DISPLAY if display else UI.BODY
	var point_size: int = int(font_size * text_scale)
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, point_size).x
	draw_string(font, Vector2((size.x - width) * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, point_size, color)

func title_fits() -> bool:
	for line in power.name.split("\n"):
		if UI.DISPLAY.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, int(22 * text_scale)).x > size.x - 16: return false
	return true

func _draw() -> void:
	if card.is_empty(): return
	var color: Color = Color(Content.SPECIES[individual.species].color)
	var contour = PackedVector2Array([Vector2(0, 11), Vector2(11, 0), Vector2(size.x - 11, 0), Vector2(size.x, 11), Vector2(size.x, size.y - 11), Vector2(size.x - 11, size.y), Vector2(11, size.y), Vector2(0, size.y - 11), Vector2(0, 11)])
	draw_colored_polygon(contour, Color("ede2c7") if not disabled else Color("b4b5a4"))
	draw_polyline(contour, UI.GOLD if chosen else color.darkened(0.25), 3, true)
	draw_line(Vector2(12, 6), Vector2(size.x - 12, 6), color.darkened(0.2), 3)
	if has_focus(): draw_polyline(contour, Color("fff8dd"), 5, true)
	draw_circle(Vector2(22, 22), 15, Color("20343a"))
	draw_string(UI.BODY, Vector2(15, 29), str(power.cost), HORIZONTAL_ALIGNMENT_LEFT, -1, 21, UI.PAPER)
	if chosen:
		draw_circle(Vector2(size.x - 21, 21), 12, Color("24493a"))
		draw_string(UI.BODY, Vector2(size.x - 29, 28), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, UI.PAPER)
	elif card.power == Content.SPECIES[individual.species].signature:
		draw_string(UI.BODY, Vector2(size.x - 31, 29), "✦", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("7a583c"))
	var lines: PackedStringArray = power.name.split("\n")
	for i in range(lines.size()): _center_text(lines[i], 57 + i * 26, 22, UI.INK, true)
	draw_circle(Vector2(size.x * 0.5, 131), 43, Color("20343a"))
	draw_arc(Vector2(size.x * 0.5, 131), 45, 0, TAU, 48, Color(color.darkened(0.1), 0.8), 1, true)
	draw_texture_rect(art_texture, Rect2(Vector2(size.x * 0.5 - 40, 91), Vector2(80, 80)), false)
	var first: String = "%d dano" % effect.direct_damage if int(effect.direct_damage) > 0 else "%d escudo" % effect.block if int(effect.block) > 0 else "%d cura" % effect.heal
	var second: String = "+%d queimadura" % effect.burn_added if int(effect.burn_added) > 0 else "%d escudo · %d cura" % [effect.block, effect.heal] if int(effect.block) > 0 and int(effect.heal) > 0 else "%d escudo" % effect.block if int(effect.direct_damage) > 0 and int(effect.block) > 0 else ""
	_center_text(first, 196, 20, UI.INK)
	_center_text(second, 217, 15, Color("3b554b"))
	_center_text(Content.display_name(individual), 237, 15, Color("4f5b50"))
