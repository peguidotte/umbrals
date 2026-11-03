extends SceneTree
## Semantic snapshot used both against source resources and the actual exported PCK.
const Content = preload("res://scripts/content.gd")
const Appearance = preload("res://scripts/catalog/presentation_catalog.gd")
const Rules = preload("res://scripts/rules.gd")

func encode(value: Variant) -> Variant:
	if value is Script: return value.resource_path
	if value is Resource:
		if value.get_script() == null: return value.resource_path
		var result: Dictionary = {}
		for property in value.get_property_list():
			if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
				result[property.name] = encode(value.get(property.name))
		return result
	if value is Array or value is PackedStringArray:
		var items: Array = []
		for item in value: items.append(encode(item))
		return items
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[key] = encode(value[key])
		return result
	if value is Vector2: return [value.x, value.y]
	if value is Color: return [value.r, value.g, value.b, value.a]
	return value

func _init() -> void:
	var game = Rules.new()
	game.new_run(42013)
	print(JSON.stringify({"catalog": {"species": encode(Content.DATABASE), "expedition": encode(Content.EXPEDITION), "items": encode(Content.ITEMS), "style": encode(Appearance.STYLE)}, "fixture_entry_present": ResourceLoader.exists("res://tests/browser/fixture_entry.gd"), "fixture_scene_present": ResourceLoader.exists("res://tests/browser/fixture_entry.tscn"), "fixture_data_present": FileAccess.file_exists("res://tests/browser/fixtures.json"), "initial_run": game.snapshot()}))
	quit()
