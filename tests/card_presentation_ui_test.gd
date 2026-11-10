extends SceneTree
const Content = preload("res://scripts/content.gd")
const Rules = preload("res://scripts/rules.gd")
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Targets = preload("res://scripts/ui/card_target_view.gd")
const Card = preload("res://scripts/ui/power_card.gd")
const Catalog = preload("res://scripts/assets/card_visual_catalog.gd")
const Renderer = preload("res://scripts/ui/card_renderer.gd")
var checks: int = 0
var failed: int = 0

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed += 1
		printerr("FAIL: " + message)

func _init() -> void: call_deferred("run")

func run() -> void:
	Catalog.preview_enabled = true
	var run_state = Expedition.new()
	run_state.new_run(42013, "partial", "dew")
	var before: Dictionary = run_state.snapshot()
	var lonlon: Dictionary = Rules.make_umbral("dew", "vital", 1)
	lonlon.slot = 1
	var foli: Dictionary = Rules.make_umbral("moss", "vital", 2)
	foli.slot = 0
	var niscor: Dictionary = Rules.make_umbral("volt", "fierce", 3, "tempestral")
	niscor.slot = 2
	var party: Array = [lonlon, foli, niscor]
	var foe: Dictionary = {"uid": 1001, "species": "moss", "form_id": "moss", "slot": 1, "name": "Esporo", "art": "characters/spore", "private_plan": {"damage": 999}}
	var entry: Dictionary = {"instance_id": "preview-card", "owner": 1, "power": "dew_mend", "target_slot": 0}
	var power: Dictionary = Content.POWERS.dew_mend
	var target: Dictionary = Targets.project(entry, power, lonlon, party, [foe], true)
	expect(target.kind == "single" and target.uid == 2 and target.portrait_key == "moss", "Healing badge follows current allied semantic slot")
	expect(Targets.project(entry, power, lonlon, party, [foe], false).kind == "none", "Canceling selection clears the target")
	entry.target_slot = 2
	expect(Targets.project(entry, power, lonlon, party, [foe], true).uid == 3, "Changing slot changes the actual recipient")
	entry.target_slot = 0
	expect(Targets.project(entry, power, lonlon, [lonlon, niscor], [foe], true).kind == "empty", "A vacant slot never borrows another portrait")
	expect(Targets.project(entry, {"scope": "upper_pair"}, lonlon, party, [foe], true).kind == "area", "Paired scope has an area representation")
	expect(Targets.project(entry, {"scope": "all"}, lonlon, party, [foe], true).kind == "area", "All scope has an area representation")
	expect(Targets.project(entry, {"scope": "single", "target": "self"}, lonlon, party, [foe], true).uid == 1, "Self target ignores the card's target slot")
	entry.target_slot = 1
	var enemy: Dictionary = Targets.project(entry, {"scope": "single", "target": "enemy"}, lonlon, party, [foe], true)
	expect(enemy.portrait_key == "characters/spore" and not enemy.has("private_plan"), "Enemy portrait uses explicit public art identity, never its aliased form/plan")
	var opponent: Dictionary = Rules.make_umbral("moss", "vital", 1003, "verdalio")
	opponent.slot = 1
	var opponent_target: Dictionary = Targets.project(entry, {"scope": "single", "target": "enemy"}, lonlon, party, [opponent], true)
	expect(opponent_target.enemy and opponent_target.portrait_source == "form" and opponent_target.label.contains(Content.display_name(opponent)), "An opposing Umbral retains its side while explicitly selecting its actual form portrait/name")
	var opponent_visual: Dictionary = Catalog.active().resolve_target_visual(opponent_target)
	expect(opponent_visual.texture != null and opponent_visual.uid == 1003, "Actual opposing form portrait resolves without borrowing an encounter-art alias")
	expect(Catalog.active().resolve_target_visual({"kind": "single", "portrait_source": "unknown", "portrait_key": "verdalio"}).texture == null, "Unknown portrait namespaces fail safely")
	foe.uid = 1002
	foe.name = "Novo ocupante"
	expect(Targets.project(entry, {"scope": "single", "target": "enemy"}, lonlon, party, [foe], true).uid == 1002, "Slot occupant changes update recipient identity")
	var card: Button = Card.new()
	root.add_child(card)
	card.size = Vector2(160, 240)
	card.configure(entry, lonlon, party, 1.12, true)
	card.set_public_target(target)
	card.set_chosen(true)
	expect(card.presentation.visual.frame != null and card.presentation.visual.art != null and card.presentation.placeholder_caption == "ARTE EM REVISÃO", "Preview loads the exact family/attack candidate and explicitly marks review status")
	var layout: Dictionary = card.presentation.visual.layout.duplicate(true)
	var geometry: Dictionary = Renderer.geometry(Vector2(160, 208), layout)
	expect(geometry.art.size.y >= geometry.canvas.size.y * .6 and geometry.art.size.x >= geometry.canvas.size.x * .8, "Reference composition reserves most of the card for the actual illustration")
	expect((Renderer.card_font() as FontVariation).base_font == Renderer.NAME_FONT and Renderer.card_font().variation_opentype.get(TextServerManager.get_primary_interface().name_to_tag("wght")) == 700, "Card names use the existing botanical-gold serif's real bold master")
	expect(Renderer.card_font().get_string_size("Gota serena", HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x > Renderer.NAME_FONT.get_string_size("Gota serena", HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x, "The engine actually applies the bold axis instead of silently rendering the default Light master")
	expect(geometry.cost.x > geometry.canvas.get_center().x and geometry.cost.y > geometry.target.y, "Actual cost is below the upper-right target badge as in the reference")
	expect(is_equal_approx(geometry.canvas.size.x / geometry.canvas.size.y, float(layout.aspect)) and geometry.canvas.position.x > 0, "The authored aspect fits inside the existing hand without stretching the frame")
	var anchored: Vector2 = geometry.canvas.position + Vector2(float(layout.anchors.target[0]), float(layout.anchors.target[1])) * geometry.canvas.size
	expect(geometry.target.is_equal_approx(anchored), "Target uses its authored normalized anchor inside the fitted frame")
	layout.anchors.title[1] = .21
	layout.anchors.owner[1] = .86
	layout.anchors.cost[0] = .16
	layout.anchors.target[0] = .8
	var moved: Dictionary = Renderer.geometry(Vector2(160, 208), layout)
	expect(moved.title != geometry.title and moved.owner != geometry.owner and moved.cost != geometry.cost and moved.target != geometry.target, "Changing each authored anchor moves its actual presentation geometry")
	var text_rect: Rect2 = Renderer.title_content_rect(geometry, true)
	expect(is_equal_approx(text_rect.get_center().x, geometry.title_rect.get_center().x) and is_equal_approx(Renderer.title_content_rect(geometry, false).get_center().x, text_rect.get_center().x), "Showing the target/cost preserves the painted title plaque's center")
	expect(text_rect.end.x < geometry.cost.x - maxf(10, geometry.canvas.size.y * .035), "Title letters end before the actual target/cost badge, including long titles")
	for id: String in Content.POWERS:
		var text: Dictionary = Renderer.text_layout(str(Content.POWERS[id].name).replace("\n", " "), text_rect.size, 18, int(layout.text.title_max_lines))
		expect(text.fits and text.lines.size() <= 2, "Actual enlarged title layout fits the pilot hand: " + id)
	expect(card.presentation.target.texture != null and card.presentation.target.uid == 2, "Selected card resolves the exact target miniature")
	expect(card.presentation.visual.style.title_plate != null and card.presentation.visual.style.owner_plate != null and card.presentation.visual.style.title_plate != card.presentation.visual.style.owner_plate, "Title and owner use distinct exact components of the same type style")
	expect(card.accessibility_name.contains("Lonlon") and card.accessibility_name.contains("Foli") and card.accessibility_name.contains("ARTE EM REVISÃO"), "Accessible text includes owner, recipient and pending review status")
	var copy: Button = Card.new()
	root.add_child(copy)
	copy.configure({"instance_id": "copy", "owner": 1, "power": "dew_mend"}, lonlon, party, 1.0, true)
	expect(copy.presentation.visual.frame == card.presentation.visual.frame and copy.presentation.visual.style.title_plate == card.presentation.visual.style.title_plate, "UID/copy/stat differences do not duplicate exact components")
	copy.configure({"instance_id": "copy", "owner": 3, "power": "tidal_splash"}, niscor, party, 1.0, true)
	var shared = Card.new()
	root.add_child(shared)
	shared.configure({"instance_id": "shared", "owner": 1, "power": "tidal_splash"}, lonlon, party, 1.0, true)
	expect(copy.presentation.visual.style.title_plate == shared.presentation.visual.style.title_plate and copy.individual.form_id != shared.individual.form_id, "Same legal Water power shares type style across two different families")
	var adult: Dictionary = Rules.make_umbral("moss", "vital", 2, "verdalio")
	for attack: String in ["thorn_lash", "root_wall"]:
		copy.configure({"instance_id": "adult-copy", "owner": 2, "power": attack}, adult, [adult], 1.0, true)
		var adult_art: Texture2D = copy.presentation.visual.art
		copy.configure({"instance_id": "initial-copy", "owner": 2, "power": attack}, foli, [foli], 1.0, true)
		expect(adult_art != null and adult_art != copy.presentation.visual.art, "Adult/initial " + attack + " have distinct exact illustrations")
	var old_key: String = card.presentation.visual.key
	var evolved: Dictionary = Rules.make_umbral("dew", "vital", 1, "mareveu")
	card.configure(entry, evolved, party, 1.12, true)
	expect(card.presentation.visual.key != old_key and card.card.instance_id == "preview-card" and card.individual.uid == 1, "Evolution invalidates visual identity while retaining physical card/UID")
	card.set_public_target({"kind": "none"})
	card.set_chosen(false)
	expect(card.presentation.target.kind == "none", "Existing card instance removes its badge on cancellation")
	expect(not Content.can_learn(lonlon, "thorn_lash"), "The conceptual Lonlon/Forest combination remains nonplayable")
	expect(run_state.snapshot() == before, "View/projection/configuration leave gameplay, save identity and RNG untouched")
	card.queue_free()
	copy.queue_free()
	shared.queue_free()
	await process_frame
	print(JSON.stringify({"suite": "card_presentation_ui", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)
