class_name UmbralPowerCard
extends Button
const Models = preload("res://scripts/domain/models.gd")
const Content = preload("res://scripts/content.gd")
const Rules = preload("res://scripts/rules.gd")
const Copy = preload("res://scripts/ui/power_copy.gd")
const UI = preload("res://scripts/ui/kit.gd")
var catalog: Content.Catalog = Content.DEFAULT
var card: Models.CardInstance
var individual: Models.Individual
var effect: Models.CastEvaluation
var power: Content.Power
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
	custom_minimum_size = UI.tokens.card.size
	pivot_offset = custom_minimum_size * 0.5

func configure(data: Models.CardInstance, umbral: Models.Individual, team: Array[Models.Individual], large: float, reduce: bool, definitions: Content.Catalog = null) -> void:
	if definitions != null: catalog = definitions
	card = data
	individual = umbral
	power = catalog.power_stats(card.power, individual)
	effect = Rules.evaluate([card], team, 0, catalog)
	art_texture = load(power.art_path)
	text_scale = large
	reduced_motion = reduce
	tooltip_text = "%s — %s\n%d dano · %d escudo · %d cura\nTrait: %s\nPassiva: %s\nC: inspeção detalhada" % [power.name.replace("\n", " "), catalog.display_name(individual), effect.damage, effect.block, effect.heal, catalog.trait_text(individual), catalog.passives[individual.passive].description]
	tooltip_text = power.identity.description + "\n" + tooltip_text
	var additional: Array[String] = Copy.special_effects(power)
	if not additional.is_empty(): tooltip_text += "\n" + " · ".join(additional)
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
	var target: Vector2 = home - Vector2(0, UI.tokens.card.selected_raise if chosen else 0) - Vector2(0, UI.tokens.card.hover_raise if raised else 0)
	var target_scale: Vector2 = Vector2.ONE * (UI.tokens.card.hover_scale if raised and not reduced_motion else 1.0)
	z_index = 6 if raised else 4 if chosen else 0
	if reduced_motion:
		position = target
		scale = target_scale
		rotation = 0 if raised else home_rotation
	else:
		movement = create_tween().set_parallel(true)
		movement.tween_property(self, "position", target, UI.tokens.motion.hover).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		movement.tween_property(self, "scale", target_scale, UI.tokens.motion.hover).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		movement.tween_property(self, "rotation", 0.0 if raised else home_rotation, UI.tokens.motion.hover)
	queue_redraw()

func _center_text(text: String, y: float, font_size: int, color: Color, display: bool = false) -> void:
	var font: Font = UI.tokens.display if display else UI.tokens.body
	var point_size: int = int(font_size * text_scale)
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, point_size).x
	draw_string(font, Vector2((size.x - width) * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, point_size, color)

func title_fits() -> bool:
	for line in power.name.split("\n"):
		if UI.tokens.display.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, int(UI.tokens.card.title_size * text_scale)).x > size.x - 16: return false
	return true

func _draw() -> void:
	if card == null: return
	var color: Color = Color(catalog.species[individual.species_id].color)
	var cut: float = UI.tokens.card.corner_cut
	var contour = PackedVector2Array([Vector2(0, cut), Vector2(cut, 0), Vector2(size.x - cut, 0), Vector2(size.x, cut), Vector2(size.x, size.y - cut), Vector2(size.x - cut, size.y), Vector2(cut, size.y), Vector2(0, size.y - cut), Vector2(0, cut)])
	draw_colored_polygon(contour, UI.tokens.card_surface if not disabled else UI.tokens.card_disabled)
	draw_polyline(contour, UI.tokens.gold if chosen else color.darkened(0.25), UI.tokens.card.border_width, true)
	draw_line(Vector2(12, 6), Vector2(size.x - 12, 6), color.darkened(0.2), 3)
	if has_focus(): draw_polyline(contour, UI.tokens.card_focus, UI.tokens.card.focus_width, true)
	draw_circle(Vector2(22, 22), 15, UI.tokens.card_inset)
	draw_string(UI.tokens.body, Vector2(15, 29), str(power.cost), HORIZONTAL_ALIGNMENT_LEFT, -1, 21, UI.tokens.paper)
	if chosen:
		draw_circle(Vector2(size.x - 21, 21), 12, UI.tokens.card_selected)
		draw_string(UI.tokens.body, Vector2(size.x - 29, 28), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, UI.tokens.paper)
	elif power.signature:
		draw_string(UI.tokens.body, Vector2(size.x - 31, 29), "✦", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, UI.tokens.card_signature)
	var lines: PackedStringArray = power.name.split("\n")
	for i in range(lines.size()): _center_text(lines[i], UI.tokens.card.title_y + i * UI.tokens.card.title_gap, UI.tokens.card.title_size, UI.tokens.ink, true)
	draw_circle(Vector2(size.x * 0.5, UI.tokens.card.art_y), UI.tokens.card.art_radius, UI.tokens.card_inset)
	draw_arc(Vector2(size.x * 0.5, UI.tokens.card.art_y), UI.tokens.card.art_radius + 2, 0, TAU, 48, Color(color.darkened(0.1), 0.8), 1, true)
	draw_texture_rect(art_texture, Rect2(Vector2(size.x * 0.5 - UI.tokens.card.art_size / 2, UI.tokens.card.art_y - UI.tokens.card.art_size / 2), Vector2.ONE * UI.tokens.card.art_size), false)
	var lines_of_effect: Array[String] = Copy.card_lines(power, effect)
	_center_text(lines_of_effect[0], UI.tokens.card.main_y, UI.tokens.card.main_size, UI.tokens.ink)
	_center_text(lines_of_effect[1], UI.tokens.card.minor_y, UI.tokens.card.minor_size, UI.tokens.card_secondary)
	_center_text(catalog.display_name(individual), UI.tokens.card.owner_y, UI.tokens.card.minor_size, UI.tokens.card_owner)

func apply_motion(reduce: bool, definitions: Content.Catalog = null) -> void:
	if definitions != null: catalog = definitions
	reduced_motion = reduce
	_react()
