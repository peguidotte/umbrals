extends SceneTree
## Isolated production-flow checks; visual approval remains separate.
var app: Control
var checks: int = 0
var failures: int = 0
func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: "+message)
func press(id: String) -> void:
	var button: BaseButton = app.registry.get(id)
	if not is_instance_valid(button) or button.disabled:
		expect(false,"Reachable control "+id)
		return
	button.grab_focus()
	button.pressed.emit()
	await process_frame
	await process_frame
func _init() -> void:
	call_deferred("run")
func persisted() -> String:
	return JSON.stringify(app.session.run_save.load_snapshot())
func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var title: Control = app.screen_host.menu_root
	expect(title.buttons.size()==(3 if OS.has_feature("web") else 4),"Four primary native actions; Web omits Quit")
	expect(title.buttons[0].text=="Continuar" and title.buttons[1].text=="Novo jogo" and title.buttons[2].text=="Opções","Primary labels and order match the selected reference")
	expect(title.buttons[0].disabled and root.gui_get_focus_owner()==app.registry["menu.play"],"Missing checkpoint keeps Continue visible/disabled and focuses New")
	expect(title.notice.text=="Nenhuma expedição salva neste dispositivo.","Missing checkpoint has a visible explanation")
	expect(title.actors.size()==4,"Four independently rendered actors")
	root.size = Vector2i(800,600)
	await process_frame
	await process_frame
	expect(title.actions.columns==2,"Four-to-three profile composes a two-column grid")
	title.buttons[2].grab_focus()
	for down in [true,false]:
		var event = InputEventKey.new()
		event.keycode = KEY_UP
		event.physical_keycode = KEY_UP
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame
	expect(root.gui_get_focus_owner()==title.buttons[1],"Up from Options skips disabled Continue to the next enabled action in the upper row")
	root.size = Vector2i(1600,900)
	await process_frame
	await process_frame
	var initial_save: String = persisted()
	var rng: int = app.game.rng.state
	for actor: Control in title.actors:
		for i in range(20): actor._react()
		expect(actor.reactions_started==1,"Reaction spam is bounded for "+actor.species)
	expect(persisted()==initial_save and app.game.rng.state==rng,"Decorative reactions preserve storage and gameplay RNG")
	title.apply_preferences(true,false,1.0)
	var resting: Dictionary = title.effect_state()
	await create_timer(0.2).timeout
	expect(title.effect_state()==resting,"Reduced motion freezes all current actor frames")
	await press("menu.play")
	expect(app.screens.top()=="starter","New opens existing starter choice directly")
	expect(persisted()==initial_save,"Opening starter choice does not create a save")
	app._pop()
	await process_frame
	expect(app.screens.top()=="menu" and persisted()==initial_save,"Cancel starter preserves clean profile")
	await press("menu.play")
	var starts: Array = []
	app.runtime.run_reset_requested.connect(func(value: int, fresh: bool): starts.append([value,fresh]))
	await press("starter.ember")
	app.menu_screens.starter_requested.emit("ember")
	await process_frame
	expect(app.screens.top()=="map" and starts.size()==1,"Repeated starter activation commits one run")
	var saved: String = persisted()
	var stable: String = JSON.stringify(app.session.expedition.snapshot())
	expect(saved!=initial_save,"Existing owner persists the chosen starter")
	app._return_menu()
	await process_frame
	expect(not title.buttons[0].disabled,"Saved checkpoint enables Continue on title")
	await press("menu.play")
	expect(app.screens.top()=="confirm_new" and root.gui_get_focus_owner()==app.registry["new.cancel"],"New with save focuses safe cancellation")
	await press("new.cancel")
	expect(app.screens.top()=="menu" and persisted()==saved,"Cancel confirmation preserves exact checkpoint")
	await press("menu.play")
	await press("new.confirm")
	expect(app.screens.top()=="starter" and persisted()==saved,"Confirm only opens choice without replacing save")
	app._pop()
	await process_frame
	expect(app.screens.top()=="menu" and persisted()==saved,"Back from confirmed choice preserves save")
	await press("menu.continue")
	expect(app.screens.top()=="map" and JSON.stringify(app.session.expedition.snapshot())==stable,"Continue restores the complete map/cards/RNG snapshot")
	expect(title.visible and not title.input_active,"Outgoing title fades without delaying navigation or accepting repeated input")
	await create_timer(0.28).timeout
	expect(not title.visible and title.z_index==0 and title.modulate==Color.WHITE,"Exit fade releases the title within the bounded transition")
	app._return_menu()
	await process_frame
	for status: String in ["corrupt","incompatible","io_error","checking","missing","cleared"]:
		title.set_checkpoint(false,status,"")
		expect(title.buttons[0].disabled and not title.notice.text.is_empty(),"Distinct accessible save state "+status)
		if status=="incompatible":
			title.buttons[1].pressed.emit()
			expect(app.screens.top()=="menu" and persisted()==saved,"Incompatible checkpoint disables New without writes")
	title.set_checkpoint(true,"recovered","Recuperamos o último progresso válido da expedição.")
	expect(not title.buttons[0].disabled and not title.notice.text.is_empty(),"Recovered checkpoint remains resumable with warning")
	app._update_continue_button()
	await press("menu.settings")
	expect(not title.input_active and title.actors.all(func(actor: Control): return not actor.active),"Modal suppresses every actor's input and processing")
	for target: String in ["codex","help","credits"]:
		await press("settings."+target)
		expect(app.screens.top()==target,"Secondary screen remains reachable: "+target)
		app._pop()
		await process_frame
		expect(app.screens.top()=="settings" and root.gui_get_focus_owner()==app.registry["settings."+target],"Back restores secondary opener: "+target)
	await press("settings.practice")
	expect(app.screens.top()=="starter","Practice remains available through Options")
	app._pop()
	await process_frame
	expect(app.screens.top()=="settings" and persisted()==saved,"Cancel practice preserves checkpoint")
	await press("settings.back")
	expect(app.screens.top()=="menu" and root.gui_get_focus_owner()==app.registry["menu.settings"],"Options returns focus to title opener")
	var before_nodes: int = get_node_count()
	for i in range(30):
		await press("menu.settings")
		await press("settings.back")
	await process_frame
	expect(get_node_count()<=before_nodes+2,"Thirty modal cycles have bounded node lifetime")
	expect(persisted()==saved,"Modal cycles preserve expedition bytes")
	app.preferences.set_value("reduced_motion",true)
	await process_frame
	expect(app.screen_host.menu_root.reduced_motion,"Preferences immediately reach current title")
	var retiring: Array[WeakRef] = []
	for player: Node in app.audio.get_children():
		if player is AudioStreamPlayer and player.has_stream_playback(): retiring.append(weakref(player.get_stream_playback()))
	app.audio.shutdown()
	var deadline: int = Time.get_ticks_msec()+2000
	while retiring.any(func(reference: WeakRef) -> bool: return reference.get_ref()!=null) and Time.get_ticks_msec()<deadline:
		await process_frame
	expect(not retiring.any(func(reference: WeakRef) -> bool: return reference.get_ref()!=null),"Audio playbacks drain before teardown")
	app.queue_free()
	await process_frame
	print(JSON.stringify({"suite":"title_menu_scoped","checks":checks,"failed":failures}))
	call_deferred("quit",0 if failures==0 else 1)
