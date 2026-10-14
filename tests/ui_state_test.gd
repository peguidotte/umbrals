extends SceneTree
const Stack = preload("res://scripts/ui/screen_stack.gd")
const Preferences = preload("res://scripts/ui/preferences.gd")
var checks: int = 0
var failed: int = 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func _init() -> void:
	var stack = Stack.new()
	expect(stack.top() == "menu" and stack.entries.size() == 1, "Boot opens only the menu")
	stack.reset("battle")
	stack.push("pause")
	stack.push("settings")
	expect(stack.entries == ["battle", "pause", "settings"], "Settings preserve their pause and combat parents")
	stack.push("settings")
	expect(stack.entries.size() == 3, "Opening the same screen twice does not duplicate it")
	expect(stack.pop() and stack.top() == "pause", "Back from settings restores pause")
	expect(stack.pop() and stack.top() == "battle", "Back from pause restores combat")
	expect(not stack.pop() and stack.root() == "battle", "Back cannot remove the root screen")
	stack.push("confirm_menu")
	stack.reset("menu")
	expect(stack.entries == ["menu"], "Returning to title clears abandoned overlays")
	var preferences = Preferences.new()
	expect(preferences.set_value("music", 2.0) and preferences.values.music == 1.0, "Volume is clamped to a usable range")
	expect(preferences.set_value("music", -1.0) and preferences.values.music == 0.0, "Zero volume can mute the music")
	expect(not preferences.set_value("sfx", "loud"), "Invalid volume types are rejected")
	expect(not preferences.set_value("reduced_motion", 1), "Motion preference requires a boolean")
	expect(not preferences.set_value("unknown", true), "Unknown preferences cannot be injected")
	preferences.set_value("reduced_motion", true)
	preferences.set_value("large_text", true)
	var loaded = Preferences.new()
	loaded.load_saved()
	expect(loaded.values.reduced_motion and loaded.values.large_text and loaded.values.music == 0, "Valid local preferences survive loading")
	expect(is_equal_approx(loaded.text_scale(), 1.12), "Large text has an explicit scaling policy")
	print(JSON.stringify({"suite": "ui_state", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)
