extends RefCounted
## Small local saves: synchronous Web Storage in browsers, atomic files on desktop.
## Legacy Godot files remain readable so an upgrade preserves existing player data.

static func read_json(path: String, web_key: String, legacy_path: String = "") -> Dictionary:
	if OS.has_feature("web"):
		var stored: Variant = JavaScriptBridge.eval("(() => { try { return window.localStorage.getItem(%s); } catch (_) { return null; } })()" % JSON.stringify(web_key), true)
		if stored is String:
			var data: Variant = JSON.parse_string(stored)
			if data is Dictionary: return data
	for candidate in [path, legacy_path]:
		if candidate.is_empty() or not FileAccess.file_exists(candidate): continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(candidate))
		if data is Dictionary: return data
	return {}

static func write_json(path: String, web_key: String, data: Dictionary) -> bool:
	var encoded: String = JSON.stringify(data)
	if OS.has_feature("web"):
		# FileAccess.close() only queues the Web filesystem's asynchronous IndexedDB sync.
		# These tiny records must survive navigation as soon as the control acknowledges it.
		# Verify bytes synchronously instead of trusting only a raw JS boolean
		# return from an input callback.
		var response: Variant = JavaScriptBridge.eval("(() => { try { const k = %s, v = %s; window.localStorage.setItem(k, v); return JSON.stringify({ok: window.localStorage.getItem(k) === v}); } catch (_) { return JSON.stringify({ok:false}); } })()" % [JSON.stringify(web_key), JSON.stringify(encoded)], true)
		if not response is String: return false
		var verified: Variant = JSON.parse_string(response)
		return verified is Dictionary and verified.get("ok", false) == true
	var temporary: String = path + ".tmp"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if not file: return false
	file.store_string(encoded)
	file.flush()
	var error: int = file.get_error()
	file.close()
	if error != OK: return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK
