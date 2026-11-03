extends SceneTree
const Content = preload("res://scripts/content.gd")
const UI = preload("res://scripts/ui/kit.gd")
var app: Control
var checks: int = 0
var failed: int = 0

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + message)

func press(id: String) -> void:
	var button: Button = app.navigation.controls[id]
	button.grab_focus()
	button.pressed.emit()
	await process_frame

func _init() -> void:
	call_deferred("run")

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await press("menu.play")
	for id in ["hud.inventory", "hud.help", "hud.pause"]:
		expect(not app.navigation.controls[id].get_global_rect().intersects(app.battle.enemy_name.get_global_rect()), "HUD avoids enemy title: " + id)
	await press("hud.inventory")
	expect(app.screens.top() == "inventory" and app.overlay.z_index > 6, "Inventory uses the screen stack and modal layer")
	expect(app.navigation.controls["inventory.use.1"].disabled, "Full-health potion visibly disables use")
	expect(root.gui_get_focus_owner() != null, "Inventory has initial keyboard focus")
	var before: int = app.game.preview_round().evaluation.damage
	await press("inventory.equip.2.1")
	expect(app.game.inventory.items[1].equipped_uid == 1, "Relic button routes through session equipment command")
	expect(app.navigation.controls["inventory.equip.2.1"].disabled, "Current equipped choice is disabled after refresh")
	await press("inventory.remove.2")
	expect(app.game.inventory.items[1].equipped_uid == -1, "Equipment can return to bag")
	await press("inventory.back")
	expect(app.screens.top() == "battle" and root.gui_get_focus_owner().get_meta("ui_id") == "hud.inventory", "Closing bag restores opener focus")
	app.game.player_hp = 32
	app.game.state_changed.emit("fixture")
	await press("hud.inventory")
	expect(app.navigation.controls["inventory.use.1"].text == "USAR · +8 FÔLEGO", "Use control displays actual projected healing")
	var rounds: int = app.game.plays
	await press("inventory.use.1")
	expect(app.game.player_hp == 40 and app.game.inventory.items[0].quantity == 0 and app.game.plays == rounds, "Use command heals once without spending round")
	expect(app.navigation.controls["inventory.use.1"].disabled, "Spent consumable cannot be activated again")
	app.preferences.set_value("large_text", true)
	await process_frame
	expect(app.screens.top() == "inventory" and app.overlay != null, "Large text rebuild preserves inventory screen")
	for id in ["hud.inventory", "hud.help", "hud.pause"]:
		expect(not app.navigation.controls[id].get_global_rect().intersects(app.battle.enemy_name.get_global_rect()), "Large HUD avoids enemy title: " + id)
	await press("inventory.back")
	app.game.enemy_hp = 1
	app.game.enemy_block = 50
	for index in range(app.game.hand.size()):
		if app.game.hand[index].power == "fireball":
			app.game.selected.assign([index])
			break
	app.game.state_changed.emit("fixture_shield")
	await process_frame
	expect(app.game.preview_round().enemy_hp_after == 1, "Enemy shield prevents lethal raw power")
	expect(not "cairá" in app.battle.notice_label.text, "HUD uses projected survival rather than raw damage")
	expect("ESCUDO" in app.battle.burn_label.text, "Current enemy shield is visible in battle")
	var original: Color = UI.tokens.paper
	UI.tokens.paper = Color("ffdddd")
	var kit = UI.new()
	var native: Theme = kit.make_theme()
	expect(native.get_color("font_color", "Label") == UI.tokens.paper and app.battle.cards[0].UI.tokens.paper == UI.tokens.paper, "Native Theme and custom cards read same style Resource")
	UI.tokens.paper = original
	expect(UI.tokens.card.size == Vector2(180, 244) and UI.tokens.motion.projectile == 0.22, "Authored style retains reference geometry and timing")
	app.audio.shutdown()
	await create_timer(0.12).timeout
	root.remove_child(app)
	app.queue_free()
	await process_frame
	print(JSON.stringify({"suite": "growth_ui", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)
