extends SceneTree
## Serialize authored resource values, never process-local object instance strings.
const Content = preload("res://scripts/content.gd")
const Expedition = preload("res://scripts/expedition/expedition.gd")

func canonical(value: Variant) -> Variant:
	if value is Script: return {"script": value.resource_path.trim_suffix("c") if value.resource_path.ends_with(".gdc") else value.resource_path}
	if value is Resource:
		var fields: Dictionary = {}
		for property in value.get_property_list():
			if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and int(property.usage) & PROPERTY_USAGE_STORAGE:
				fields[str(property.name)] = canonical(value.get(property.name))
		return {"resource": value.resource_path, "fields": fields}
	if value is Dictionary:
		var fields: Dictionary = {}
		for key in value: fields[key] = canonical(value[key])
		return fields
	if value is Array:
		var items: Array = []
		for item in value: items.append(canonical(item))
		return items
	return value

func _init() -> void:
	var definition_script: Script = Content
	var run = Expedition.new()
	run.new_run(42013)
	var authored: Dictionary = {"definitions": canonical(definition_script.get_script_constant_map()), "species": canonical(Content.CATALOG), "projection": canonical(Content.SPECIES), "passive_pools": canonical(Content.PASSIVE_POOLS), "asset_lock": JSON.parse_string(FileAccess.get_file_as_string("res://assets/runtime-lock.json"))}
	print(JSON.stringify({"catalog": authored, "initial_run": run.snapshot(), "fixture_entry_present": ResourceLoader.exists("res://tests/browser/fixture_entry.gd"), "fixture_scene_present": ResourceLoader.exists("res://tests/browser/fixture_entry.tscn"), "fixture_data_present": FileAccess.file_exists("res://tests/browser/fixtures.json")}))
	quit()
