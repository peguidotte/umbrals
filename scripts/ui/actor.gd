class_name UmbralActor
extends Button
## A stable, targetable lateral slot. Labels and hit areas do not follow idle animation.
const Content = preload("res://scripts/content.gd")
const BattleArt = preload("res://scripts/ui/battle_art.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")
const UI = preload("res://scripts/ui/kit.gd")
var portrait: TextureRect
var caption: Label
var passive_caption: Label
var intent_caption: Label
var identity: Dictionary = {}
var reduced_motion: bool = false
var still: bool = false
var idle_clock: float = 0.0
var accent: Color = UI.GOLD
var enemy: bool = false
var slot: int = 1
var target_marked: bool = false
var targeted: bool = false
var target_available: bool = false
var acting: bool = false
var public_intent: Dictionary = {}
var text_scale: float = 1.0
var ground_profile: Dictionary = {}
var shadow_width: float = 80.0

func _ready() -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	caption = UI.new().label("", 19, UI.PAPER, true, true)
	add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -53
	caption.offset_bottom = -31
	passive_caption = UI.new().label("", 15, UI.MUTED, false, true)
	add_child(passive_caption)
	passive_caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	passive_caption.offset_top = -12
	passive_caption.offset_bottom = 4
	intent_caption = UI.new().label("", 15, UI.PAPER, false, true)
	intent_caption.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(intent_caption)
	intent_caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	intent_caption.offset_top = 8 if slot == 0 else 0
	intent_caption.offset_bottom = 31 if slot == 0 else 23
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(_pivot)
	_pivot()

func _pivot() -> void:
	if is_instance_valid(portrait) and is_instance_valid(portrait.texture) and not ground_profile.is_empty():
		var foot: Vector2 = Vector2(float(ground_profile.foot[0]), float(ground_profile.foot[1]))
		var depth: float = [0.90, 1.0, 1.07][clampi(slot, 0, 2)]
		var factor: float = minf((size.x - 32) / portrait.texture.get_width(), 118.0 * depth / maxf(1, foot.y - float(ground_profile.visible_top)))
		portrait.size = portrait.texture.get_size() * factor
		if portrait.flip_h: foot.x = portrait.texture.get_width() - foot.x
		portrait.pivot_offset = foot * factor
		# The opaque feet, rather than the transparent atlas rectangle, meet the floor.
		portrait.position = _ground() - portrait.pivot_offset
		shadow_width = float(ground_profile.width) * factor
	queue_redraw()

func _ground() -> Vector2:
	return Vector2(size.x * 0.5, size.y - 58)

func set_identity(data: Dictionary, scale_text: float = 1.0) -> void:
	identity = data.duplicate(true)
	text_scale = scale_text
	if data.is_empty():
		portrait.texture = null
		caption.text = "Vaga " + ["superior", "central", "inferior"][slot]
		caption.modulate = Color(1, 1, 1, 0.45)
		passive_caption.text = ""
		tooltip_text = "Vaga %s · sem retaguarda" % ["superior", "central", "inferior"][slot]
	else:
		var species: Dictionary = Content.SPECIES.get(data.get("species", ""), {})
		var art: String = str(data.get("art", ""))
		if art.is_empty() and not species.is_empty(): art = str(species.art[int(data.stage) - 1])
		portrait.texture = BattleArt.texture(art)
		ground_profile = BattleArt.ground_profile(art)
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if portrait.texture is AtlasTexture else CanvasItem.TEXTURE_FILTER_LINEAR
		portrait.flip_h = enemy and not portrait.texture is AtlasTexture
		var alive: bool = int(data.get("hp", 1)) > 0
		portrait.modulate = (Color(0.94, 0.97, 1.0) if slot == 0 else Color.WHITE) if alive else Color(0.4, 0.48, 0.56, 0.6)
		accent = Color(species.get("color", "dec88d"))
		caption.text = str(data.name) if data.has("name") else Content.display_name(data)
		caption.modulate = Color.WHITE
		caption.add_theme_color_override("font_color", accent if alive else UI.MUTED)
		var tags: Array[String] = []
		if not alive: tags.append("INCAPACITADO")
		else:
			tags.append_array(Conditions.labels(data))
			if int(data.get("block", 0)) > 0: tags.append("Escudo %d" % data.block)
			if int(data.get("revive_ready_round", 0)) > 0: tags.append("Reanimado")
		passive_caption.text = " · ".join(tags.slice(0, 2)) + (" · +%d" % (tags.size() - 2) if tags.size() > 2 else "") if not tags.is_empty() else "VEL %d" % int(data.get("speed", 0))
		tooltip_text = "%s\nHP %d/%d · ATQ %d · DEF %d · VEL %d\nVaga %s. C: inspecionar." % [caption.text, int(data.get("hp", 0)), int(data.get("max_hp", 0)), int(data.get("attack", 0)), int(data.get("defense", 0)), int(data.get("speed", 0)), ["superior", "central", "inferior"][slot]]
		tooltip_text += "\n" + Content.nature_text(data) + " · Resistências: " + Content.resistance_text(data)
		tooltip_text += "\n" + "\n".join(Conditions.labels(data, true))
	caption.add_theme_font_size_override("font_size", int(19 * scale_text))
	passive_caption.add_theme_font_size_override("font_size", int(14 * scale_text))
	intent_caption.add_theme_font_size_override("font_size", int(14 * scale_text))
	set_intent(public_intent)
	_pivot()
	queue_redraw()

func set_intent(data: Dictionary) -> void:
	public_intent = data
	if not is_instance_valid(intent_caption): return
	intent_caption.text = ""
	intent_caption.tooltip_text = ""
	if identity.is_empty() or int(identity.get("hp", 0)) <= 0 or not enemy: return
	var category: String = str(data.get("category", "hidden"))
	var names: Dictionary = {"attack": "⚔ ATAQUE", "defend": "◆ DEFESA", "defense": "◆ DEFESA", "prepare": "◌ PREPARO", "support": "✦ SUPORTE", "heal": "✚ CURA", "hidden": "? INTENÇÃO OCULTA", "unknown": "? INTENÇÃO OCULTA"}
	intent_caption.text = str(names.get(category, category.to_upper()))
	if data.has("damage"):
		var scope: String = str(data.get("scope", "single"))
		if category == "attack":
			intent_caption.text += " %d poder · " % int(data.damage)
			intent_caption.text += ["SUP", "CEN", "INF"][clampi(int(data.get("target_slot", 1)), 0, 2)] if scope == "single" else {"upper_pair": "SUP+CEN", "lower_pair": "CEN+INF", "all": "TODOS"}.get(scope, "TODOS")
		elif category in ["defend", "defense"]:
			intent_caption.text += " +%d" % int(data.get("block", 0))
		elif category == "prepare": intent_caption.text += " +%d carga" % int(data.get("charge", 0))
	if data.has("nature") and Content.NATURES.has(str(data.nature)):
		intent_caption.tooltip_text = "Natureza anunciada: " + Content.NATURES[str(data.nature)].name
		for id in data.get("conditions", {}):
			intent_caption.tooltip_text += "\n" + Conditions.DEFINITIONS[id].name + ": " + Conditions.DEFINITIONS[id].description
	intent_caption.add_theme_color_override("font_color", UI.FIRE if category == "attack" else UI.GOLD)
	queue_redraw()

func _process(delta: float) -> void:
	if not is_instance_valid(portrait): return
	if still or reduced_motion:
		portrait.scale = Vector2.ONE
		return
	idle_clock += delta
	# Breathing keeps the foot pivot fixed to its ground anchor.
	portrait.scale = Vector2(1.0 + sin(idle_clock * 1.4 + float(identity.get("uid", 0))) * 0.006, 1.0 + sin(idle_clock * 1.4 + float(identity.get("uid", 0))) * 0.009)

func _draw() -> void:
	var ground: Vector2 = _ground()
	if acting:
		draw_style_box(UI.new().style(Color(UI.GOLD, 0.07), UI.GOLD, 0), Rect2(10, 22, size.x - 20, size.y - 18))
	if not identity.is_empty():
		# Soft ambient occlusion plus a tight contact core; footprint follows anatomy.
		for layer in range(3):
			var width: float = shadow_width * [1.16, 0.98, 0.72][layer]
			var height: float = [16.0, 10.0, 4.0][layer] * [0.90, 1.0, 1.07][clampi(slot, 0, 2)]
			draw_set_transform(ground + Vector2(0, 1), 0, Vector2(width * 0.5, height * 0.5))
			draw_circle(Vector2.ZERO, 1, Color(0.015, 0.025, 0.035, [0.10, 0.20, 0.34][layer]))
		draw_set_transform(Vector2.ZERO)
	if target_available:
		draw_set_transform(ground, 0, Vector2(1, 0.24))
		draw_arc(Vector2.ZERO, maxf(42, shadow_width * 0.65), 0, TAU, 40, UI.GOLD if target_marked else Color(UI.PAPER, 0.3), 4 if target_marked else 2, true)
		draw_set_transform(Vector2.ZERO)
	if has_focus() or is_hovered():
		var color: Color = UI.GOLD if targeted else accent
		draw_style_box(UI.new().style(Color(color, 0.05), Color(color, 0.65), 0), Rect2(8, 19, size.x - 16, size.y - 1))
	if target_marked: draw_string(UI.BODY, Vector2(size.x * 0.5 - 9, size.y - 62), "▼", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UI.GOLD)
	if not identity.is_empty():
		var bar: Rect2 = Rect2(size.x * 0.18, size.y - 28, size.x * 0.64, 14)
		draw_rect(bar.grow(3), Color("0b1423"))
		draw_rect(bar, Color("283443"))
		var fraction: float = float(identity.get("hp", 0)) / maxf(1, float(identity.get("max_hp", 1)))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * fraction, bar.size.y)), Color("7dbb9b") if not enemy else Color("dc967c"))
		var hp: String = "%d / %d" % [int(identity.get("hp", 0)), int(identity.get("max_hp", 0))]
		var width: float = UI.BODY.get_string_size(hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(UI.BODY, Vector2((size.x - width) * 0.5, size.y - 17), hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.PAPER)
