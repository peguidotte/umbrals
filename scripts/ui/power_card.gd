class_name UmbralPowerCard
extends Button
signal pose_settled
const Companion = preload("res://scripts/battle/aquatic_companion.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
const Content = preload("res://scripts/content.gd")
const UI = preload("res://scripts/ui/kit.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")
const Rules = preload("res://scripts/rules.gd")
const CardCatalog = preload("res://scripts/assets/card_visual_catalog.gd")
const Presentation = preload("res://scripts/ui/card_presentation.gd")
const Renderer = preload("res://scripts/ui/card_renderer.gd")
const RAISED_Z: int = 20
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
var owner_texture: Texture2D
var art_texture: Texture2D
var placed: bool = false
var insufficient_actions: bool = false
var blocked: bool = false
var blocked_caption: String = "INDISPONÍVEL"
var target_caption: String = ""
var presentation_catalog: RefCounted
var presentation: Dictionary = {}
var _owner_visual: Dictionary = {}
var _owner_visual_key: String = ""
var _public_target: Dictionary = {"kind": "none"}
var _base_tooltip: String = ""
var display_only: bool = false
var fanned: bool = false:
	set(value):
		if fanned == value: return
		fanned = value
		# A selected card moves immediately. Commit this UI gesture on press,
		# before the animation can move its release hit area under the pointer.
		action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS if value else BaseButton.ACTION_MODE_BUTTON_RELEASE
var hand_order: int = 0
var pose_in_motion: bool = false
var fan_prominent: bool = false

func _ready() -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]: add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_react)
	mouse_exited.connect(_react)
	focus_entered.connect(_focus_card)
	focus_exited.connect(_react)
	if not display_only: custom_minimum_size = Vector2.ZERO

func configure(data: Dictionary, umbral: Dictionary, team: Array, large: float, reduce: bool, revision: int = 0) -> void:
	card = data
	individual = umbral
	power = Content.power_stats(str(card.power), individual)
	var able_count: int = team.filter(func(member: Dictionary) -> bool: return int(member.get("slot", -1)) >= 0 and int(member.hp) > 0).size()
	effect = Rules.power_effect(card, individual, able_count)
	art_texture = Assets.texture(power.art)
	owner_texture = UI.BattleArt.texture(Content.art_binding(individual))
	text_scale = large
	reduced_motion = reduce
	tooltip_text = "%s — %s\n%d ação(ões) · %d potência · %d escudo · %d cura\n%s\nSelecione e clique em uma vaga para mudar o alvo. Q/E: alvo. P: plano. C: detalhes." % [str(power.name).replace("\n", " "), Content.display_name(individual), int(power.cost), int(effect.get("damage", 0)), int(effect.get("block", 0)), int(effect.get("heal", 0)), _scope_label()]
	tooltip_text += "\n" + Content.NATURES[power.nature].name + "\n" + effect_text(effect)
	tooltip_text += "\nExecução: %s · Velocidade %d" % ["prioritária" if int(power.get("priority", 0)) > 0 else "normal", int(individual.get("speed", 0))]
	if Companion.available(individual, effect, revision): tooltip_text += "\n" + Companion.description()
	_base_tooltip = tooltip_text
	if presentation_catalog == null: presentation_catalog = CardCatalog.active()
	if presentation_catalog != null:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var key: String = "/".join([presentation_catalog.release_key, str(individual.species), Content.form_id(individual), str(card.power), str(power.nature)])
		if key != _owner_visual_key:
			_owner_visual_key = key
			_owner_visual = presentation_catalog.resolve_owner_visual(str(individual.species), Content.form_id(individual), str(card.power), str(power.nature))
		_refresh_presentation()
	queue_redraw()

func set_public_target(target: Dictionary) -> void:
	if _public_target == target: return
	_public_target = target.duplicate(true)
	if presentation_catalog != null and not card.is_empty(): _refresh_presentation()
	queue_redraw()

func _refresh_presentation() -> void:
	var owner_view: Dictionary = {"uid": individual.uid, "species": individual.species, "form_id": Content.form_id(individual), "name": Content.display_name(individual)}
	presentation = Presentation.build(card, owner_view, power, effect, _owner_visual, presentation_catalog.resolve_target_visual(_public_target))
	tooltip_text = _base_tooltip
	if not str(_public_target.get("label", "")).is_empty(): tooltip_text += "\nAlvo: " + str(_public_target.label)
	if not presentation.placeholder_caption.is_empty(): tooltip_text += "\n" + presentation.placeholder_caption
	accessibility_name = "%s · %s · %d · %s" % [str(power.name).replace("\n", " "), Content.display_name(individual), int(individual.uid), tooltip_text]

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
	pose_in_motion = false
	if display_only:
		position = home
		rotation = home_rotation
		scale = Vector2.ONE
		queue_redraw()
		return
	var raised: bool = has_focus() or is_hovered()
	var lifted: bool = fanned and fan_prominent and chosen
	var zoom: float = 1.4 if lifted else 1.0
	var target: Vector2 = home - Vector2(0, (145 if lifted else 18 if chosen else 0) if fanned else (10 if chosen else 0) + (5 if raised else 0))
	if lifted:
		# Bring this same button forward within the fan's middle corridor so it
		# cannot cover either team's lower body/target. Other cards stay in hand.
		var extent: float = (get_parent() as Control).size.x
		target.x = clampf(target.x, extent * .3, extent * .7 - size.x)
	var angle: float = 0 if lifted or not fanned else home_rotation
	z_index = RAISED_Z if lifted else 10 if chosen else hand_order if fanned else 0
	if fanned: get_parent().sync_layers()
	if reduced_motion:
		position = target
		scale = Vector2.ONE * zoom
		rotation = angle
		pose_settled.emit()
	else:
		pose_in_motion = true
		movement = create_tween().set_parallel(true)
		movement.tween_property(self, "position", target, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		movement.tween_property(self, "scale", Vector2.ONE * zoom, 0.14)
		movement.tween_property(self, "rotation", angle, 0.14)
		movement.finished.connect(_pose_finished)
	queue_redraw()

func _pose_finished() -> void:
	pose_in_motion = false
	pose_settled.emit()

func _focus_card() -> void:
	if fanned and chosen: get_parent().present(hand_order)
	_react()

func _title_size() -> int:
	return int(16 * text_scale)

func _title_lines() -> Array[String]:
	var lines: Array[String] = []
	var line: String = ""
	for word in str(power.get("name", "")).replace("\n", " ").split(" "):
		var candidate: String = word if line.is_empty() else line + " " + word
		if not line.is_empty() and UI.BODY.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, _title_size()).x > size.x - 12:
			lines.append(line)
			line = word
		else: line = candidate
	if not line.is_empty(): lines.append(line)
	return lines

func _center_text(value: String, y: float, font_size: int, color: Color) -> void:
	var width: float = UI.BODY.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(UI.BODY, Vector2((size.x - width) * 0.5, y), value, HORIZONTAL_ALIGNMENT_LEFT, size.x - 10, font_size, color)

func title_fits() -> bool:
	if not presentation.is_empty():
		var layout: Dictionary = presentation.visual.layout
		var positions: Dictionary = Renderer.geometry(size, layout)
		var rect: Rect2 = Renderer.title_content_rect(positions, chosen and presentation.target.get("kind", "none") != "none")
		return Renderer.text_layout(str(power.name).replace("\n", " "), rect.size, int(18 * text_scale * maxf(1, positions.canvas.size.y / 240.0)), int(layout.get("text", {}).get("title_max_lines", 2))).fits
	for line in _title_lines():
		if UI.BODY.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, _title_size()).x > size.x - 10: return false
	return true

func _draw() -> void:
	if card.is_empty(): return
	if not presentation.is_empty():
		Renderer.draw(self, presentation, owner_texture, {"chosen": chosen, "focused": has_focus(), "aiming": aiming, "prominent": fan_prominent, "blocked": blocked, "blocked_caption": blocked_caption, "insufficient_actions": insufficient_actions, "text_scale": text_scale})
		return
	var color: Color = Color(Content.SPECIES[individual.species].color)
	var contour: PackedVector2Array = PackedVector2Array([Vector2(0, 8), Vector2(8, 0), Vector2(size.x - 8, 0), Vector2(size.x, 8), Vector2(size.x, size.y - 8), Vector2(size.x - 8, size.y), Vector2(8, size.y), Vector2(0, size.y - 8), Vector2(0, 8)])
	draw_colored_polygon(contour, UI.RAISED if chosen else UI.INK)
	draw_polyline(contour, UI.GOLD if chosen else UI.BORDER, 3 if chosen else 2, true)
	if has_focus(): draw_polyline(contour, UI.PAPER, 3, true)
	var gem := PackedVector2Array([Vector2(7, 6), Vector2(30, 6), Vector2(34, 19), Vector2(19, 33), Vector2(4, 19), Vector2(7, 6)])
	draw_colored_polygon(gem, UI.RAISED)
	draw_polyline(gem, UI.FIRE if insufficient_actions else UI.CRYSTAL, 2)
	draw_string(UI.BODY, Vector2(13, 25), str(power.cost), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UI.PAPER)
	if chosen:
		if aiming: draw_string(UI.BODY, Vector2(size.x - 37, 23), "ALVO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.GOLD)
		else: draw_string(UI.BODY, Vector2(size.x - 26, 25), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, UI.GOLD)
	if chosen and aiming:
		draw_rect(Rect2(5, 31, size.x - 10, 3), UI.GOLD)
	draw_string(UI.BODY, Vector2(38, 24), Content.NATURES[power.nature].name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 45, 12, Color(Content.NATURES[power.nature].color))
	var art_size: float = minf(82, size.x * 0.74)
	draw_texture_rect(art_texture, Rect2(Vector2((size.x - art_size) * 0.5, 33), Vector2.ONE * art_size), false, Color(1, 1, 1, 0.35) if blocked else Color.WHITE)
	var y: float = 125
	var title_size: int = _title_size()
	for line in _title_lines():
		_center_text(line, y, title_size, UI.MUTED if blocked else UI.PAPER)
		y += title_size + 2
	var first: String = "%d poder" % floori(float(effect.damage) * float(effect.get("attack_multiplier", 1.0))) if int(effect.get("damage", 0)) > 0 else "%d escudo" % int(effect.block) if int(effect.get("block", 0)) > 0 else "%d cura" % int(effect.get("heal", 0))
	_center_text(blocked_caption if blocked else first, size.y - 43, int(16 * text_scale), UI.FIRE if blocked else color)
	_center_text("SEM AÇÕES" if insufficient_actions else target_caption if chosen and not target_caption.is_empty() else _scope_label(), size.y - 25, int(13 * text_scale), UI.GOLD if chosen else UI.MUTED)
	draw_line(Vector2(6, size.y - 21), Vector2(size.x - 6, size.y - 21), UI.BORDER, 1)
	var portrait_rect := Rect2(6, size.y - 22, 25, 23)
	draw_texture_rect(owner_texture, portrait_rect, false)
	var owner_name: String = "%s · %d" % [Content.display_name(individual), int(individual.uid)]
	draw_string(UI.BODY, Vector2(34, size.y - 5), owner_name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 38, int(12 * text_scale), UI.PAPER)
