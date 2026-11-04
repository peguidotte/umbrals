extends SceneTree
const Content = preload("res://scripts/content.gd")
var app: Control
var checks: int = 0
var failed: int = 0
func _init() -> void: call_deferred("run")
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		printerr("FAIL: ",message)
func text_of(node: Node) -> String:
	var text: String = node.text if node is Label or node is Button else ""
	for child in node.get_children(): text += "\n"+text_of(child)
	return text
func press(id: String) -> void:
	var control: Control = app.registry.get(id)
	if not is_instance_valid(control) or not control.is_inside_tree():
		expect(false,"Reachable control "+id)
		return
	control.grab_focus()
	for down in [true,false]:
		var event = InputEventKey.new()
		event.keycode = KEY_ENTER
		event.physical_keycode = KEY_ENTER
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame
	for frame in range(4): await process_frame
func has_control(id: String) -> bool:
	for node in app.screen_host.modal_root.find_children("*","Control",true,false):
		if node.get_meta("ui_id","") == id: return true
	return false
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/codex-story/"+name+".png")
func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.visual_capture = true
	app.preferences.values.reduced_motion = true
	for id in ["ember","moss","ignivar"]: app.codex_progress.mark("umbrals",id)
	app.codex_progress.mark("powers","fireball")
	app.codex_progress.mark("items","potion")
	await process_frame
	await press("menu.codex")
	expect(app.screen_host.modal_root.record_section == "story","History is the default record tab")
	expect(Content.UMBRAL_LORE.ember.text in text_of(app.screen_host.modal_root.details),"Brasa's actual lore is rendered")
	expect(not "Evolução" in text_of(app.screen_host.modal_root.details),"No dedicated evolution panel")
	expect(has_control("codex.evolution") and app.registry["codex.evolution"].text == "Ver Ignivar","Known form is a compact named shortcut")
	await capture("01-brasa-history")
	await press("codex.section.details")
	expect("Combustão" in text_of(app.screen_host.modal_root.details),"Trait appears in mechanics tab")
	expect(has_control("codex.related.fireball"),"Related powers remain navigable")
	await capture("02-brasa-powers")
	await press("codex.related.fireball")
	expect(Content.POWER_DESCRIPTIONS.fireball in text_of(app.screen_host.modal_root.details),"Power description comes from catalog")
	app._pop()
	for frame in range(4): await process_frame
	expect(app.screen_host.modal_root.record_section == "details" and app.screen_host.modal_root.selected == "ember","Back restores the originating tab")
	expect(root.gui_get_focus_owner() == app.registry["codex.related.fireball"],"Back restores power link focus")
	await press("codex.evolution")
	expect(Content.UMBRAL_LORE.ignivar.text in text_of(app.screen_host.modal_root.details),"Evolved form has its own history")
	expect(app.registry["codex.evolution"].text == "Ver Brasa","Form shortcut also returns to the base form")
	app._pop()
	for frame in range(4): await process_frame
	await press("codex.entry.moss")
	expect(Content.UMBRAL_LORE.moss.text in text_of(app.screen_host.modal_root.details),"Musgo has distinct lore")
	expect(not has_control("codex.evolution"),"Undiscovered evolution has no revealing shortcut")
	expect(not "Verdálio" in text_of(app.screen_host.modal_root.details),"Undiscovered evolution name stays hidden")
	await capture("03-musgo-history")
	await press("codex.entry.volt")
	expect(not has_control("codex.section.story"),"Unknown record cannot open lore tabs")
	expect(not Content.UMBRAL_LORE.volt.text in text_of(app.screen_host.modal_root.details),"Unknown lore remains hidden")
	await press("codex.tab.items")
	expect(app.registry["codex.section.story"].text == "Descrição","Items use Description tab")
	expect(Content.ITEM_DESCRIPTIONS.potion in text_of(app.screen_host.modal_root.details),"Item has authored descriptive content")
	await capture("04-item-description")
	await press("codex.section.details")
	expect("Restaura 18 HP." in text_of(app.screen_host.modal_root.details),"Item effect remains tied to actual numbers")
	expect("Custa 1 ação" in text_of(app.screen_host.modal_root.details),"Item action cost remains accurate")
	await capture("05-item-effect")
	app.preferences.set_value("large_text",true)
	for frame in range(4): await process_frame
	expect(app.screen_host.modal_root.text_scale > 1,"Large text applies to the record")
	await capture("06-large-text")
	app.audio.shutdown()
	root.remove_child(app)
	app.queue_free()
	await create_timer(0.2).timeout
	for frame in range(4): await process_frame
	print(JSON.stringify({"suite":"codex_story","checks":checks,"failed":failed}))
	call_deferred("quit",1 if failed else 0)
