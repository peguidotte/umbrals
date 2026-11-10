extends RefCounted
## Draw-only composition. All assets/view models are prepared before _draw.
const UI = preload("res://scripts/ui/kit.gd")
const INK: Color = Color("102027")
const GOLD: Color = Color("edc679")
const NAME_FONT = preload("res://assets/fonts/cormorant/versions/1.0.0/display.ttf")
static var _font: FontVariation
static var _readout_font: FontVariation

static func card_font() -> Font:
	if _font == null:
		_font = FontVariation.new()
		_font.base_font = NAME_FONT
		# Use the actual bold master, rather than expanding a regular serif's
		# outlines. This is the existing botanical-gold display family.
		_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
	return _font

static func readout_font() -> Font:
	if _readout_font == null:
		_readout_font = FontVariation.new()
		_readout_font.base_font = UI.DISPLAY
		_readout_font.variation_embolden = .6
	return _readout_font

static func _rect(canvas: Rect2, values: Array) -> Rect2:
	return Rect2(canvas.position + Vector2(float(values[0]), float(values[1])) * canvas.size, Vector2(float(values[2]), float(values[3])) * canvas.size)

static func geometry(dimensions: Vector2, layout: Dictionary) -> Dictionary:
	var aspect: float = maxf(.01, float(layout.get("aspect", 2.0 / 3)))
	var fitted: Vector2 = Vector2(minf(dimensions.x, dimensions.y * aspect), minf(dimensions.y, dimensions.x / aspect))
	var canvas: Rect2 = Rect2((dimensions - fitted) * .5, fitted)
	var result: Dictionary = {"canvas": canvas, "background": _rect(canvas, layout.get("safe_region", [.05, .05, .9, .9])), "art": _rect(canvas, layout.get("art_region", [.12, .255, .76, .54]))}
	var defaults: Dictionary = {"title": [.5, .17], "owner": [.5, .88], "cost": [.13, .06], "target": [.86, .07]}
	for key: String in defaults:
		var anchor: Array = layout.get("anchors", {}).get(key, defaults[key])
		result[key] = canvas.position + Vector2(float(anchor[0]), float(anchor[1])) * canvas.size
	result.title_rect = Rect2(result.title - fitted * Vector2(.86, .14) * .5, fitted * Vector2(.86, .14))
	result.owner_rect = Rect2(result.owner - fitted * Vector2(.88, .11) * .5, fitted * Vector2(.88, .11))
	return result

static func title_content_rect(positions: Dictionary, occupied_badge: bool) -> Rect2:
	var result: Rect2 = positions.title_rect.grow_individual(-4, -1, -4, -1)
	if occupied_badge:
		# Reserve both ends equally: the target/cost must not move the title's
		# center away from the center of its painted plaque.
		var inset: float = positions.canvas.size.x * .11
		result = result.grow_individual(-inset, 0, -inset, 0)
	return result

static func _wrap(value: String, width: float, font_size: int, font: Font) -> Array[String]:
	var lines: Array[String] = []
	var line: String = ""
	for word: String in value.split(" "):
		var candidate: String = word if line.is_empty() else line + " " + word
		if not line.is_empty() and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
			lines.append(line)
			line = word
		else: line = candidate
	if not line.is_empty(): lines.append(line)
	return lines

static func text_layout(value: String, dimensions: Vector2, base_size: int, max_lines: int = 1, font: Font = null) -> Dictionary:
	if font == null: font = card_font()
	var font_size: int = maxi(8, base_size)
	var lines: Array[String] = []
	var fits: bool = false
	while font_size >= 8:
		lines.clear()
		if max_lines > 1: lines = _wrap(value, dimensions.x, font_size, font)
		else: lines.append(value)
		fits = lines.size() <= max_lines and font.get_height(font_size) * lines.size() <= dimensions.y
		for line: String in lines:
			fits = fits and font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= dimensions.x
		if fits or font_size == 8: break
		font_size -= 1
	return {"lines": lines, "font_size": font_size, "fits": fits}

static func _fit_text(card: Control, text: String, rect: Rect2, base_size: int, color: Color, max_lines: int = 1, outline: bool = false, font: Font = null) -> void:
	if font == null: font = readout_font()
	var measured: Dictionary = text_layout(text, rect.size, base_size, max_lines, font)
	var font_size: int = measured.font_size
	var line_height: float = font.get_height(font_size)
	var y: float = rect.get_center().y - line_height * measured.lines.size() * .5 + font.get_ascent(font_size)
	for line: String in measured.lines:
		var width: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var baseline: Vector2 = Vector2(rect.get_center().x - width * .5, y)
		if outline: card.draw_string_outline(font, baseline, line, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, font_size, 2, INK)
		card.draw_string(font, baseline, line, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, font_size, color)
		y += line_height

static func photo_contour(rect: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	# Matches the native SVG contour. The illustration itself is clipped to the
	# same bowed corners, so no rectangular painting leaks through the perimeter.
	var corners: Array = [[Vector2(.12, 0), Vector2.ZERO, Vector2(0, .08)], [Vector2(0, .92), Vector2(0, 1), Vector2(.12, 1)], [Vector2(.88, 1), Vector2.ONE, Vector2(1, .92)], [Vector2(1, .08), Vector2(1, 0), Vector2(.88, 0)]]
	for curve: Array in corners:
		for step: int in range(9):
			var t: float = step / 8.0
			var point: Vector2 = curve[0] * (1 - t) * (1 - t) + curve[1] * 2 * (1 - t) * t + curve[2] * t * t
			points.append(rect.position + point * rect.size)
	return points

static func _cover(card: Control, texture: Texture2D, destination: Rect2, crop: Array = [0, 0, 1, 1], focal: Array = [], clip: PackedVector2Array = PackedVector2Array()) -> void:
	var source: Rect2 = Rect2(Vector2(float(crop[0]), float(crop[1])) * texture.get_size(), Vector2(float(crop[2]), float(crop[3])) * texture.get_size())
	var ratio: float = maxf(destination.size.x / source.size.x, destination.size.y / source.size.y)
	var visible: Vector2 = destination.size / ratio
	var center: Vector2 = Vector2(float(focal[0]), float(focal[1])) * texture.get_size() if focal.size() == 2 else source.get_center()
	center = center.clamp(source.position + visible * .5, source.end - visible * .5)
	source = Rect2(center - visible * .5, visible)
	if clip.is_empty():
		card.draw_texture_rect_region(texture, destination, source)
	else:
		var uv := PackedVector2Array()
		for point: Vector2 in clip: uv.append((source.position + (point - destination.position) / destination.size * source.size) / texture.get_size())
		card.draw_polygon(clip, PackedColorArray([Color.WHITE]), uv, texture)

static func _contain(card: Control, texture: Texture2D, destination: Rect2) -> void:
	var dimensions: Vector2 = texture.get_size() * minf(destination.size.x / texture.get_width(), destination.size.y / texture.get_height())
	card.draw_texture_rect(texture, Rect2(destination.get_center() - dimensions * .5, dimensions), false)

static func draw(card: Control, model: Dictionary, owner_portrait: Texture2D, state: Dictionary) -> void:
	var visual: Dictionary = model.visual
	var style: Dictionary = visual.style
	var layout: Dictionary = visual.layout
	var positions: Dictionary = geometry(card.size, layout)
	var canvas: Rect2 = positions.canvas
	var tokens: Dictionary = style.get("tokens", {})
	var accent: Color = Color(str(tokens.get("background", "#d7c9a4")))
	var foreground: Color = Color(str(tokens.get("foreground", "#102027")))
	var zoom: float = float(state.get("text_scale", 1.0)) * maxf(1, canvas.size.y / 240.0)
	var shade: Color = Color(1, 1, 1, .42) if state.get("blocked", false) else Color.WHITE
	var background: Rect2 = positions.background
	var selected: bool = state.get("chosen", false) or state.get("focused", false)
	if selected and visual.get("frame") is Texture2D:
		card.draw_texture_rect(visual.frame, canvas.grow(canvas.size.x * .015), false, Color(1.15, 1, .55, .48))
	var art: Rect2 = positions.art
	var contour: PackedVector2Array = photo_contour(art)
	card.draw_colored_polygon(contour, Color("142f32"))
	if visual.get("art") is Texture2D: _cover(card, visual.art, art, [0, 0, 1, 1], [], contour)
	elif owner_portrait != null: _contain(card, owner_portrait, art.grow(-5))
	if visual.get("frame") is Texture2D:
		card.draw_texture_rect(visual.frame, canvas, false, shade)
	else:
		# A missing family remains neutral and explicitly pending; never borrow a frame.
		card.draw_rect(background, GOLD, false, 2)
	if style.get("art_border") is Texture2D: card.draw_texture_rect(style.art_border, art, false, shade)
	if not visual.get("frame") is Texture2D:
		var caption: Rect2 = Rect2(art.position + Vector2(5, 7), Vector2(art.size.x - 10, 14))
		card.draw_rect(caption, INK)
		_fit_text(card, "SEM MOLDURA", caption, 9, UI.PAPER)
	var title: Rect2 = positions.title_rect
	var owner: Rect2 = positions.owner_rect
	for pair: Array in [["title_plate", title], ["owner_plate", owner]]:
		if style.get(pair[0]) is Texture2D: card.draw_texture_rect(style[pair[0]], pair[1], false, shade)
		else: card.draw_rect(pair[1], accent)
	var text_rules: Dictionary = layout.get("text", {})
	var occupied_badge: bool = state.get("chosen", false) and model.target.get("kind", "none") != "none"
	_fit_text(card, str(model.power_name).replace("\n", " "), title_content_rect(positions, occupied_badge), int(18 * zoom), foreground, int(text_rules.get("title_max_lines", 2)), false, card_font())
	_fit_text(card, str(model.owner_name), owner.grow_individual(-3, -1, -3, -1), int(15 * zoom), foreground, int(text_rules.get("owner_max_lines", 1)), false, card_font())
	var cost_center: Vector2 = positions.cost if occupied_badge else positions.target
	var cost_radius: float = maxf(10, canvas.size.y * .035)
	var effect: Dictionary = model.effect
	var summary: String = "%d poder" % floori(float(effect.get("damage", 0)) * float(effect.get("attack_multiplier", 1))) if int(effect.get("damage", 0)) > 0 else "%d escudo" % int(effect.get("block", 0)) if int(effect.get("block", 0)) > 0 else "%d cura" % int(effect.get("heal", 0))
	if state.get("blocked", false): summary = str(state.get("blocked_caption", "INDISPONÍVEL"))
	elif state.get("insufficient_actions", false): summary = "SEM AÇÕES"
	# Values remain visible and accessible, below the owner plaque instead of
	# covering the painting with the pilot's opaque black stripe.
	var readout: Rect2 = _rect(canvas, [.12, .953, .43, .04])
	_fit_text(card, summary, readout, int(9 * zoom), UI.PAPER, 1, true)
	if not str(model.get("placeholder_caption", "")).is_empty():
		var missing: bool = str(model.placeholder_caption) == "ARTE PENDENTE"
		var pending: Rect2 = _rect(canvas, [.12, .77, .76, .07] if missing else [.55, .953, .35, .04])
		if missing: card.draw_rect(pending, INK)
		_fit_text(card, "ARTE PENDENTE" if missing else "PRÉVIA", pending, int(9 * zoom), Color("f8e6b2"))
	if state.get("chosen", false):
		_target(card, model.target, int(effect.get("heal", 0)) > 0, positions)
		if state.get("prominent", state.get("aiming", false)) and model.target.get("kind", "none") == "single":
			# The painting is fixed per power. The live recipient is explicit next
			# to its portrait, even when the scene depicts another companion.
			var recipient: String = ("Cura: " if int(effect.get("heal", 0)) > 0 else "Alvo: ") + str(model.target.get("label", ""))
			var caption: Rect2 = Rect2(Vector2(positions.target.x - canvas.size.x * .43, canvas.position.y - canvas.size.y * .11), Vector2(canvas.size.x * .86, canvas.size.y * .055))
			card.draw_rect(caption, INK)
			_fit_text(card, recipient, caption.grow(-1), int(10 * zoom), UI.PAPER)
	# The cost intentionally overlaps the portrait's lower edge and must be
	# painted last, as in the approved reference, including area targets.
	card.draw_circle(cost_center, cost_radius, INK)
	card.draw_arc(cost_center, cost_radius, 0, TAU, 32, UI.FIRE if state.get("insufficient_actions", false) else GOLD, 2, true)
	_fit_text(card, str(model.cost), Rect2(cost_center - Vector2.ONE * cost_radius, Vector2.ONE * cost_radius * 2), int(13 * zoom), UI.PAPER)

static func _target(card: Control, target: Dictionary, healing: bool, positions: Dictionary) -> void:
	var kind: String = str(target.get("kind", "none"))
	if kind == "none": return
	var diameter: float = clampf(positions.canvas.size.x * .28, 24, 64)
	var center: Vector2 = positions.target
	var rect: Rect2 = Rect2(center - Vector2.ONE * diameter * .5, Vector2.ONE * diameter)
	card.draw_circle(center, diameter * .5 + 2, GOLD)
	card.draw_circle(center, diameter * .5, INK)
	if kind == "single" and target.get("texture") is Texture2D:
		var face: Rect2 = rect.grow(-2)
		var circle := PackedVector2Array()
		for step: int in range(40): circle.append(face.get_center() + Vector2.from_angle(step * TAU / 40) * face.size * .5)
		_cover(card, target.texture, face, target.get("crop", [0, 0, 1, 1]), target.get("focal_point", []), circle)
	else: _fit_text(card, "ÁREA" if kind == "area" else "—", rect.grow(-2), 9, UI.PAPER)
	if kind == "single":
		var mark: Rect2 = Rect2(rect.end.x - 8, rect.position.y - 3, 12, 12)
		card.draw_circle(mark.get_center(), 7, Color("196ac6"))
		_fit_text(card, "+" if healing else "→", mark, 11, Color.WHITE)
