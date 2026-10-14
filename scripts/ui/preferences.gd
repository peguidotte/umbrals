class_name UmbralPreferences
extends RefCounted
## Atomic local settings. Values are validated before use; no gameplay RNG is involved.
signal changed
const PATH = "user://umbral_preferences_v1.json"
var values: Dictionary = {"music": 0.55, "sfx": 0.8, "reduced_motion": false, "flashes": false, "large_text": false}

func load_saved() -> void:
	if not FileAccess.file_exists(PATH): return
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
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
	var temporary: String = PATH + ".tmp"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if not file:
		push_warning("Could not save preferences.")
		return
	file.store_string(JSON.stringify(values))
	file.close()
	var error: int = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(PATH))
	if error != OK: push_warning("Could not replace preferences file.")

func text_scale() -> float:
	return 1.12 if values.large_text else 1.0
