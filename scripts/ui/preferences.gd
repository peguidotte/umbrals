class_name UmbralPreferences
extends RefCounted
## Atomic local settings. Values are validated before use; no gameplay RNG is involved.
signal changed
const Storage = preload("res://scripts/storage.gd")
const PATH = "user://umbral_preferences_v1.json"
const WEB_KEY = "umbral.preferences.v1"
var values: Dictionary = {"music": 0.55, "sfx": 0.8, "reduced_motion": false, "flashes": false, "large_text": false}

func load_saved() -> void:
	var data: Dictionary = Storage.read_json(PATH, WEB_KEY)
	if data is Dictionary:
		for key in values:
			if key in ["music", "sfx"] and (data.get(key) is float or data.get(key) is int):
				values[key] = clampf(float(data[key]), 0.0, 1.0)
			elif values[key] is bool and data.get(key) is bool: values[key] = data[key]

func set_value(key: String, value: Variant) -> bool:
	if not values.has(key): return false
	if key in ["music", "sfx"]:
		if not (value is float or value is int): return false
		values[key] = clampf(float(value), 0.0, 1.0)
	else:
		if not value is bool: return false
		values[key] = value
	_save()
	changed.emit()
	return true

func _save() -> void:
	if not Storage.write_json(PATH, WEB_KEY, values):
		push_warning("Could not save preferences.")

func text_scale() -> float:
	return 1.12 if values.large_text else 1.0
