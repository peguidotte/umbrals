extends Control
## Isolated, read-only composition fixture. No Rules instance, save or gameplay grants.
const Card = preload("res://scripts/ui/power_card.gd")
const Content = preload("res://scripts/content.gd")
const Rules = preload("res://scripts/rules.gd")
const Targets = preload("res://scripts/ui/card_target_view.gd")
const Catalog = preload("res://scripts/assets/card_visual_catalog.gd")
const UI = preload("res://scripts/ui/kit.gd")
var cards: Array = []
var heading: Label
var note: Label
var large: bool = false
var concept: bool = false
var render_ready: bool = false
var warm_lookup_us: int = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Catalog.preview_enabled = true
	large = bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('large_text') === '1'")) if OS.has_feature("web") else false
	concept = bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('card_concept') === '1'")) if OS.has_feature("web") else false
	var background := ColorRect.new()
	background.color = Color("06162e")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	heading = Label.new()
	heading.text = "Identidade do Umbral, poder em ação"
	heading.add_theme_font_override("font", UI.DISPLAY)
	heading.add_theme_font_size_override("font_size", 38)
	heading.add_theme_color_override("font_color", UI.GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(heading)
	note = Label.new()
	note.text = "PRÉVIA DE COMPOSIÇÃO · catálogo incompleto e peças em revisão\nLonlon/Bosque é somente demonstração isolada; não concede aprendizado."
	note.add_theme_font_override("font", UI.BODY)
	note.add_theme_font_size_override("font_size", 18)
	note.add_theme_color_override("font_color", UI.PAPER)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(note)
	var foli: Dictionary = Rules.make_umbral("moss", "vital", 1)
	foli.slot = 0
	var folife: Dictionary = Rules.make_umbral("moss", "vital", 2, "verdalio")
	var lonlon: Dictionary = Rules.make_umbral("dew", "vital", 3)
	var niscor: Dictionary = Rules.make_umbral("volt", "fierce", 4, "tempestral")
	var definitions: Array = [[foli, "thorn_lash"], [foli, "root_wall"], [folife, "thorn_lash"], [lonlon, "tidal_splash"], [lonlon, "dew_mend"], [lonlon, "thorn_lash"], [niscor, "tidal_splash"]]
	if concept: definitions = [[foli, "thorn_lash"], [foli, "thorn_lash"], [foli, "root_wall"], [lonlon, "tidal_splash"], [lonlon, "dew_mend"], [lonlon, "thorn_lash"]]
	for i in definitions.size():
		var definition: Array = definitions[i]
		var card: Button = Card.new()
		card.display_only = true
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.focus_mode = Control.FOCUS_NONE
		add_child(card)
		var data: Dictionary = {"instance_id": "gallery-%d" % i, "owner": definition[0].uid, "power": definition[1], "target_slot": 0}
		card.configure(data, definition[0], [foli, folife, lonlon, niscor], 1.12 if large else 1.0, true)
		if i == 4:
			card.set_public_target(Targets.project(data, Content.POWERS[data.power], definition[0], [foli, lonlon], [], true))
			card.set_chosen(true)
		cards.append(card)
	resized.connect(_layout)
	_layout()
	await get_tree().process_frame
	await get_tree().process_frame
	var started: int = Time.get_ticks_usec()
	for repeat in range(100):
		Catalog.active().resolve_owner_visual("dew", "dew", "dew_mend", "water")
	warm_lookup_us = Time.get_ticks_usec() - started
	render_ready = true
	_publish()

func _layout() -> void:
	if heading == null: return
	heading.position = Vector2(24, 28)
	heading.size = Vector2(size.x - 48, 60)
	note.position = Vector2(24, minf(size.y - 90, 650))
	if concept: note.position.y = size.y - 78
	note.size = Vector2(size.x - 48, 70)
	var width: float = minf(190, (size.x - 100 - 6 * 10) / 7)
	var start: float = (size.x - (width * 7 + 60)) * .5
	for i in cards.size():
		var card: Control = cards[i]
		var zoom: float = 1.14 if i == 4 else 1.0
		card.size = Vector2(width, width * 1.5) * zoom
		var position: Vector2 = Vector2(start + i * (width + 10), 210 - (42 if i == 4 else 0))
		var angle: float = 0
		if concept:
			var fit: float = minf(size.x / 1600.0, size.y / 900.0)
			card.size = Vector2(320, 480) * fit if i == 4 else Vector2(240, 360) * fit
			position = Vector2([40, 255, 455, 655, 900, 1170][i], [360, 335, 320, 330, 150, 350][i]) * fit + Vector2((size.x - 1600 * fit) * .5, 0)
			angle = [-.2, -.12, -.06, 0, .03, .14][i]
			card.pivot_offset = card.size * .5
			card.z_index = 12 if i == 4 else i
		card.place(position, angle)
		card.queue_redraw()
	if is_inside_tree(): _publish.call_deferred()

func _publish() -> void:
	if not OS.has_feature("web") or not render_ready: return
	var rows: Array = []
	for card in cards:
		var visual: Dictionary = card.presentation.visual
		rows.append({"species": card.individual.species, "form": Content.form_id(card.individual), "owner": Content.display_name(card.individual), "power": card.card.power, "nature": card.power.nature, "frame": Catalog.texture_source(visual.frame) if visual.frame != null else "", "title_plate": Catalog.texture_source(visual.style.title_plate), "owner_plate": Catalog.texture_source(visual.style.owner_plate), "art_pending": visual.art == null, "target": card.presentation.target.kind, "target_uid": card.presentation.target.get("uid", -1), "native_title": card.power.name, "title_fits": card.title_fits(), "texture_filter": card.texture_filter})
	var metrics: Dictionary = {"catalog": Catalog.active().coverage_diagnostics(), "static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC), "render_texture_memory_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED), "warm_100_lookup_us": warm_lookup_us}
	JavaScriptBridge.eval("window.cardGalleryState = " + JSON.stringify({"ready": true, "cards": rows, "large": large, "concept": concept, "metrics": metrics, "illegal_demo_learnable": Content.can_learn({"species": "dew", "form_id": "dew"}, "thorn_lash")}), true)
