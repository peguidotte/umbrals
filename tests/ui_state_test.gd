extends SceneTree
const Stack = preload("res://scripts/ui/screen_stack.gd")
const Preferences = preload("res://scripts/ui/preferences.gd")
const Storage = preload("res://scripts/storage.gd")
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
	var current_path: String = "user://storage_test.json"
	var legacy_path: String = "user://legacy_storage_test.json"
	var legacy: Dictionary = {"runs": 3, "wins": 1}
	expect(Storage.read_json(current_path, "test.storage").is_empty(), "Missing saves start with empty data")
	expect(Storage.write_json(legacy_path, "test.legacy", legacy), "Legacy fixture is written atomically")
	var restored: Dictionary = Storage.read_json(current_path, "test.storage", legacy_path)
	expect(restored.get("runs") == 3 and restored.get("wins") == 1 and restored.size() == 2, "An existing legacy save remains readable")
	var current: Dictionary = {"runs": 4, "wins": 2}
	expect(Storage.write_json(current_path, "test.storage", current), "New records are committed to their native file")
	restored = Storage.read_json(current_path, "test.storage", legacy_path)
	expect(restored.get("runs") == 4 and restored.get("wins") == 2 and restored.size() == 2, "The current save takes precedence over legacy data")
	var corrupt = FileAccess.open(current_path, FileAccess.WRITE)
	corrupt.store_string("[]")
	corrupt.close()
	restored = Storage.read_json(current_path, "test.storage", legacy_path)
	expect(restored.get("runs") == 3 and restored.get("wins") == 1 and restored.size() == 2, "Invalid current save shapes recover from legacy data")
	Storage.write_json(Preferences.PATH, Preferences.WEB_KEY, {"music": 99, "large_text": "true", "flashes": 1})
	var validated = Preferences.new()
	validated.load_saved()
	expect(validated.values.music == 1.0, "Stored volume is validated and clamped after loading")
	expect(not validated.values.large_text and not validated.values.flashes, "Stored invalid booleans preserve safe defaults")
	print(JSON.stringify({"suite": "ui_state", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)
