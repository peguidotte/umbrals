extends SceneTree
## Scoped menu integration, using an isolated XDG directory supplied by the launcher.
var app: Control
var checks: int = 0
var failures: int = 0

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func press(id: String) -> void:
	var button: BaseButton = app.registry.get(id)
	if not is_instance_valid(button) or button.disabled:
		expect(false, "Reachable control " + id)
		return
	button.pressed.emit()
	await process_frame
	await process_frame

func _init() -> void:
	call_deferred("run")

func active_playbacks(audio: Node) -> Array[WeakRef]:
	var result: Array[WeakRef] = []
	for player in audio.get_children():
		if player is AudioStreamPlayer and player.has_stream_playback():
			result.append(weakref(player.get_stream_playback()))
	return result

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	expect(root.gui_get_focus_owner() == app.registry["menu.play"], "Initial Play focus")
	var title: Control = app.screen_host.menu_root
	expect(title.canvas.size == Vector2(1672,941) and title.buttons[0].plate is AtlasTexture, "Approved artwork coordinates and native atlas-backed controls are used")
	expect(title.buttons.size() == 6 and title.buttons[0] == app.registry["menu.play"] and title.buttons[1] == app.registry["menu.codex"], "Gold title exposes selected six-command composition and original routes")
	title.apply_preferences(true, false, 1.0)
	var resting: Dictionary = title.effect_state()
	await create_timer(0.2).timeout
	expect(title.effect_state() == resting, "Reduced motion freezes poses and pulse")
	var initial_save: String = JSON.stringify(app.session.run_save.load_snapshot())
	await press("menu.play")
	expect(app.screens.top() == "journey" and app.registry["journey.continue"].disabled, "No-save Journey disables Continue")
	expect(app.registry["journey.new"].caption.text == "NOVA EXPEDIÇÃO" and app.registry["journey.new"].caption.is_visible_in_tree(), "Native caption is rendered above its plate")
	expect(not app.screen_host.menu_root.input_active, "Journey owns title interaction")
	await press("journey.new")
	await press("starter.ember")
	expect(app.screens.top() == "map", "New expedition opens map through existing starter flow")
	var saved: String = JSON.stringify(app.session.run_save.load_snapshot())
	var stable: String = JSON.stringify(app.session.expedition.snapshot())
	expect(saved != initial_save, "Existing expedition coordinator writes the checkpoint")
	app._return_menu()
	await process_frame
	await press("menu.play")
	var journey: Control = app.screen_host.modal_root
	expect(not app.registry["journey.continue"].disabled, "Save enables Continue")
	expect(journey.public_checkpoint.party == app.session.expedition.public_state().party, "Journey presents the saved party")
	expect(journey.checkpoint_summary(journey.public_checkpoint) == "Bosque · Próxima parada: Clareira", "Journey describes the actual next node")
	expect(JSON.stringify(app.session.run_save.load_snapshot()) == saved, "Building checkpoint card is read-only")
	await press("journey.new")
	expect(app.screens.top() == "confirm_new", "New still asks before replacing existing run")
	await press("new.cancel")
	expect(JSON.stringify(app.session.run_save.load_snapshot()) == saved, "Cancel New preserves the entire checkpoint")
	await press("journey.continue")
	expect(app.screens.top() == "map" and JSON.stringify(app.session.expedition.snapshot()) == stable, "Continue restores exact map, cards and RNG")
	app._return_menu()
	await process_frame
	app.preferences.set_value("reduced_motion", true)
	await process_frame
	await press("menu.play")
	expect(app.screen_host.modal_root.modulate.a == 1.0, "Reduced motion skips menu entrance animation")
	await press("journey.back")
	expect(root.gui_get_focus_owner() == app.registry["menu.play"], "Back restores semantic Play focus")
	var roster_view = preload("res://scripts/ui/journey_menu.gd").new()
	app.add_child(roster_view)
	roster_view.size = app.size
	var public_saved: Dictionary = app.session.expedition.public_state()
	public_saved.party.clear()
	for i in range(6):
		public_saved.party.append(app.Rules.make_umbral(["ember", "dew", "moss", "volt"][i % 4], "fierce", i + 1, app.Content.legacy_form(["ember", "dew", "moss", "volt"][i % 4], 2)))
	var noop: Callable = func(): pass
	var callbacks: Array[Callable] = [noop, noop, noop, noop]
	roster_view.build(app.ui, public_saved, "", callbacks, func(_node: Control, _key: String, _screen: String): pass, true)
	await process_frame
	await process_frame
	expect(roster_view.public_checkpoint.party.size() == 6, "Checkpoint view supports all six saved individuals")
	expect(roster_view.panel.size.x <= app.size.x - 40 and roster_view.panel.size.y <= app.size.y - 40, "Six-person panel stays within viewport")
	roster_view.queue_free()
	await process_frame
	var player_count: int = app.audio.get_child_count()
	for i in range(20):
		app.audio.navigate()
		app.audio.awaken()
	expect(app.audio.get_child_count() == player_count, "Repeated cues use a bounded audio pool")
	app.preferences.set_value("music", 0.0)
	app.preferences.set_value("sfx", 0.0)
	expect(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Music mute covers title water")
	expect(AudioServer.is_bus_mute(AudioServer.get_bus_index("UI")), "SFX mute covers navigation and magic")
	for sound in [app.audio.crystal_tick, app.audio.crystal_confirm, app.audio.magic_chord, app.audio.title_water.stream]:
		var peak: int = 0
		var energy: float = 0.0
		for i in range(sound.data.size() / 2):
			var sample: int = sound.data.decode_s16(i * 2)
			peak = maxi(peak, absi(sample))
			energy += float(sample) * sample
		expect(peak > 50 and peak < 32700 and energy > 0, "Synthesized cue is nonempty and does not clip")
	var retiring: Array[WeakRef] = active_playbacks(app.audio)
	app.audio.shutdown()
	# AudioServer drains stopped playback on its mixer thread, then frees it on a
	# later main-loop update. Observe that lifecycle instead of guessing a delay.
	var deadline: int = Time.get_ticks_msec() + 2000
	while retiring.any(func(reference: WeakRef) -> bool: return reference.get_ref() != null) and Time.get_ticks_msec() < deadline:
		await process_frame
	expect(not retiring.any(func(reference: WeakRef) -> bool: return reference.get_ref() != null), "Stopped audio playbacks are released before teardown")
	app.queue_free()
	await process_frame
	print(JSON.stringify({"suite": "title_menu_scoped", "checks": checks, "failed": failures}))
	# Let this coroutine release its local AudioStream samples before engine cleanup.
	call_deferred("quit", 0 if failures == 0 else 1)
