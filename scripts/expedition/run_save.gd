extends RefCounted
## Independent, integrity-checked expedition checkpoints. Never touches profile data.

const VERSION: int = 1
const SCHEMA: String = "umbral.expedition.checkpoint"
const Storage = preload("res://scripts/storage.gd")

var last_status: String = "missing"
var _path: String
var _key: String

func _init(base_path: String = "user://umbral_run_v1.json", web_key: String = "umbral.run.v1") -> void:
	_path = base_path
	_key = web_key

func _slot_path(slot: int) -> String:
	return _path + "." + str(slot)

func _slot_key(slot: int) -> String:
	return _key + "." + str(slot)

func _read_slot(slot: int) -> Dictionary:
	var raw: Variant
	if OS.has_feature("web"):
		# Return an explicit status so blocked storage cannot masquerade as an empty slot.
		var result: Variant = JavaScriptBridge.eval("(() => { try { const v = window.localStorage.getItem(%s); return JSON.stringify({ok:true,value:v}); } catch (_) { return JSON.stringify({ok:false}); } })()" % JSON.stringify(_slot_key(slot)), true)
		var response: Variant = JSON.parse_string(str(result))
		if not response is Dictionary or not response.get("ok", false): return {"state": "io_error"}
		raw = response.get("value")
		if raw == null: return {"state": "missing"}
	else:
		var path: String = _slot_path(slot)
		if not FileAccess.file_exists(path): return {"state": "missing"}
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null: return {"state": "io_error"}
		raw = file.get_as_text()
		var error: int = file.get_error()
		file.close()
		if error != OK and error != ERR_FILE_EOF: return {"state": "io_error"}
	var parser: JSON = JSON.new()
	if parser.parse(raw) != OK: return {"state": "invalid"}
	var parsed: Variant = parser.data
	if not parsed is Dictionary: return {"state": "invalid"}
	var record: Dictionary = parsed
	if record.get("schema") != SCHEMA or record.get("version") != VERSION: return {"state": "invalid"}
	var generation: Variant = record.get("generation")
	if not (generation is int or generation is float) or generation < 1 or generation > 9007199254740991 or generation != floor(generation): return {"state": "invalid"}
	var kind: Variant = record.get("kind")
	if kind != "snapshot" and kind != "cleared": return {"state": "invalid"}
	if not record.get("snapshot") is Dictionary or not record.get("checksum") is String: return {"state": "invalid"}
	var payload: Dictionary = {"schema": SCHEMA, "version": VERSION, "generation": generation, "kind": kind, "snapshot": record["snapshot"]}
	var normalized: Variant = JSON.parse_string(JSON.stringify(payload))
	if JSON.stringify(normalized).sha256_text() != record["checksum"]: return {"state": "invalid"}
	return {"state": "valid", "generation": int(generation), "kind": kind, "snapshot": record["snapshot"]}

func _records() -> Array[Dictionary]:
	return [_read_slot(0), _read_slot(1)]

func _latest(records: Array[Dictionary]) -> int:
	var latest: int = -1
	for i in range(2):
		if records[i]["state"] == "valid" and (latest == -1 or records[i]["generation"] > records[latest]["generation"]): latest = i
	return latest

func _write(slot: int, generation: int, kind: String, snapshot: Dictionary) -> bool:
	var payload: Dictionary = {"schema": SCHEMA, "version": VERSION, "generation": generation, "kind": kind, "snapshot": snapshot}
	# Hash the same JSON representation that a subsequent reader will see.
	var normalized: Variant = JSON.parse_string(JSON.stringify(payload))
	if not normalized is Dictionary: return false
	normalized["checksum"] = JSON.stringify(normalized).sha256_text()
	var ok: Variant = Storage.write_json(_slot_path(slot), _slot_key(slot), normalized)
	if not OS.has_feature("web"): return ok == true
	# Web bridge returns can be lost during UI callbacks even when setItem ran.
	# Verify the synchronous stored record rather than assuming either outcome.
	var written: Dictionary = _read_slot(slot)
	return written["state"] == "valid" and written["generation"] == generation and written["kind"] == kind and JSON.stringify(written["snapshot"]) == JSON.stringify(normalized["snapshot"])

func save(snapshot: Dictionary) -> bool:
	var records: Array[Dictionary] = _records()
	if records.any(func(record: Dictionary) -> bool: return record["state"] == "io_error"):
		last_status = "io_error"
		return false
	var latest: int = _latest(records)
	var generation: int = 1 if latest == -1 else records[latest]["generation"] + 1
	if generation > 9007199254740991:
		last_status = "io_error"
		return false
	var target: int = 0 if latest == -1 else 1 - latest
	if not _write(target, generation, "snapshot", snapshot):
		last_status = "io_error"
		return false
	last_status = "ok"
	return true

func load_snapshot() -> Dictionary:
	var records: Array[Dictionary] = _records()
	var latest: int = _latest(records)
	if latest == -1:
		if records.any(func(record: Dictionary) -> bool: return record["state"] == "io_error"): last_status = "io_error"
		elif records.any(func(record: Dictionary) -> bool: return record["state"] == "invalid"): last_status = "corrupt"
		else: last_status = "missing"
		return {}
	if records[latest]["kind"] == "cleared":
		last_status = "cleared"
		return {}
	last_status = "recovered" if records.any(func(record: Dictionary) -> bool: return record["state"] == "invalid" or record["state"] == "io_error") else "ok"
	return records[latest]["snapshot"].duplicate(true)

func _remove(slot: int) -> bool:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(() => { try { window.localStorage.removeItem(%s); return true; } catch (_) { return false; } })()" % JSON.stringify(_slot_key(slot)), true)
		return _read_slot(slot)["state"] == "missing"
	var path: String = _slot_path(slot)
	if not FileAccess.file_exists(path): return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK

func clear() -> bool:
	var records: Array[Dictionary] = _records()
	if records.any(func(record: Dictionary) -> bool: return record["state"] == "invalid" or record["state"] == "io_error"):
		last_status = "corrupt" if records.any(func(record: Dictionary) -> bool: return record["state"] == "invalid") else "io_error"
		return false
	var latest: int = _latest(records)
	if latest == -1:
		last_status = "cleared"
		return true
	var generation: int = records[latest]["generation"] + 1
	var tombstone: int = 1 - latest
	if generation > 9007199254740991 or not _write(tombstone, generation, "cleared", {}):
		last_status = "io_error"
		return false
	# Keep the tombstone if removal of the older checkpoint fails.
	if not _remove(latest) or not _remove(tombstone):
		last_status = "io_error"
		return false
	last_status = "cleared"
	return true
