extends SceneTree
const Content = preload("res://scripts/content.gd")
const Expedition = preload("res://scripts/expedition/expedition.gd")
func _init() -> void:
	var definition_script: Script = Content
	var run = Expedition.new()
	run.new_run(42013)
	print(JSON.stringify({"catalog": {"definitions": definition_script.get_script_constant_map(), "asset_lock": JSON.parse_string(FileAccess.get_file_as_string("res://assets/runtime-lock.json"))}, "initial_run": run.snapshot(), "fixture_entry_present": ResourceLoader.exists("res://tests/browser/fixture_entry.gd"), "fixture_scene_present": ResourceLoader.exists("res://tests/browser/fixture_entry.tscn"), "fixture_data_present": FileAccess.file_exists("res://tests/browser/fixtures.json")}))
	quit()
