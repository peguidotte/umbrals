extends SceneTree

const RunSave = preload("res://scripts/expedition/run_save.gd")
const Storage = preload("res://scripts/storage.gd")
const PATH: String = "user://expedition_save_fixture.json"
const KEY: String = "test.expedition.save"
var failures: int = 0
var assertions: int = 0

func expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func remove_fixtures() -> void:
	for suffix in [".0", ".1", ".0.tmp", ".1.tmp"]:
		var path: String = PATH + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _initialize() -> void:
	remove_fixtures()
	var store = RunSave.new(PATH, KEY)
	expect(store.load_snapshot().is_empty() and store.last_status == "missing", "Missing checkpoint is reported")
	var first: Dictionary = {"rng": "-9223372036854775808", "special": "á\n\"\\\u2603", "nested": {"hand": [{"id": 41, "hp": 2.5}], "zones": [1, 2, 3]}}
	expect(store.save(first), "First checkpoint saved")
	expect(JSON.stringify(store.load_snapshot()) == JSON.stringify(JSON.parse_string(JSON.stringify(first))) and store.last_status == "ok", "Nested checkpoint and special strings roundtrip")
	var second: Dictionary = {"rng": "9223372036854775807", "round": 2}
	expect(store.save(second), "Second checkpoint saved")
	expect(JSON.stringify(store.load_snapshot()) == JSON.stringify(JSON.parse_string(JSON.stringify(second))), "Newest checkpoint selected")
	var broken: FileAccess = FileAccess.open(PATH + ".1", FileAccess.WRITE)
	broken.store_string("{truncated")
	broken.close()
	expect(JSON.stringify(store.load_snapshot()) == JSON.stringify(JSON.parse_string(JSON.stringify(first))) and store.last_status == "recovered", "Truncated latest checkpoint recovers previous record")
	expect(not store.clear() and store.last_status == "corrupt", "Clear refuses unreadable record")
	expect(store.save(second), "Saving repairs inactive slot")
	var unknown: Dictionary = Storage.read_json(PATH + ".1", KEY + ".1")
	unknown["version"] = 99
	expect(Storage.write_json(PATH + ".1", KEY + ".1", unknown), "Unknown-version fixture written")
	expect(JSON.stringify(store.load_snapshot()) == JSON.stringify(JSON.parse_string(JSON.stringify(first))) and store.last_status == "recovered", "Unknown version is rejected and prior record recovered")
	remove_fixtures()
	expect(Storage.write_json(PATH + ".0", KEY + ".0", unknown), "Unknown-version-only fixture written")
	expect(store.load_snapshot().is_empty() and store.last_status == "corrupt", "Unknown version alone is not accepted")
	remove_fixtures()
	expect(store.save(first) and store.save(second), "Checkpoints prepared for checksum test")
	var altered: Dictionary = Storage.read_json(PATH + ".1", KEY + ".1")
	altered["snapshot"]["round"] = 999
	expect(Storage.write_json(PATH + ".1", KEY + ".1", altered), "Tampered fixture written")
	expect(JSON.stringify(store.load_snapshot()) == JSON.stringify(JSON.parse_string(JSON.stringify(first))) and store.last_status == "recovered", "Checksum rejects altered snapshot")
	remove_fixtures()
	expect(store.save(first), "Checkpoint prepared for interrupted clear")
	expect(store._write(1, 2, "cleared", {}), "Interrupted clear tombstone written")
	expect(store.load_snapshot().is_empty() and store.last_status == "cleared", "Tombstone prevents an older checkpoint resurrecting")
	expect(store.clear(), "Interrupted clear can be completed")
	remove_fixtures()
	expect(store.save(first) and store.save(second), "Two checkpoints available before clear")
	expect(store.clear(), "Clear removes checkpoints")
	expect(store.load_snapshot().is_empty() and store.last_status == "missing", "Cleared checkpoint cannot resurrect")
	expect(store.clear(), "Repeated clear succeeds")
	var invalid = RunSave.new("user://missing_expedition_directory/checkpoint", KEY + ".failure")
	expect(not invalid.save(first) and invalid.last_status == "io_error", "Write failure is reported")
	remove_fixtures()
	print("Expedition save: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures else 0)
