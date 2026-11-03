extends SceneTree

const RunSave = preload("res://scripts/session/run_save.gd")
const Migration = preload("res://scripts/expedition/migration.gd")
const Identity = preload("res://scripts/expedition/identity.gd")
const Replay = preload("res://scripts/expedition/replay.gd")
const Expedition = preload("res://scripts/expedition/expedition.gd")
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
	expect(store.load_snapshot().is_empty() and store.last_status == "incompatible", "Unknown version blocks recovery to protect newer data")
	expect(not store.save(second) and store.last_status == "incompatible", "Unknown version cannot be overwritten")
	remove_fixtures()
	expect(Storage.write_json(PATH + ".0", KEY + ".0", unknown), "Unknown-version-only fixture written")
	expect(store.load_snapshot().is_empty() and store.last_status == "incompatible", "Unknown version alone is not accepted")
	remove_fixtures()
	expect(store.save(first), "Checkpoint prepared for identity mismatch")
	var foreign_record: Dictionary = Storage.read_json(PATH + ".0", KEY + ".0")
	foreign_record.identity.ruleset = "other"
	foreign_record.erase("checksum")
	foreign_record.checksum = JSON.stringify(JSON.parse_string(JSON.stringify(foreign_record))).sha256_text()
	expect(Storage.write_json(PATH + ".0", KEY + ".0", foreign_record), "Foreign identity fixture written")
	expect(store.load_snapshot().is_empty() and store.last_status == "incompatible" and not store.save(second), "Foreign identity blocks loading and overwrite")
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
	var gameplay: Dictionary = {"forms": [{"name": "Original", "art": "one", "stats": {"speed": 8}, "power_profile": {"damage": 2}}], "evolutions": [{"from": "a", "to": "b"}]}
	var digest: String = Identity.content_digest(gameplay, {}, {}, {}, [], {})
	var edited: Dictionary = gameplay.duplicate(true)
	edited.forms[0].name = "Renamed"
	edited.forms[0].art = "other"
	edited.forms[0].lore = {"title": "A new story", "text": "New prose"}
	expect(Identity.content_digest(edited, {}, {}, {}, [], {}) == digest, "Presentation and lore changes preserve gameplay identity")
	edited.forms[0].stats.speed = 9
	expect(Identity.content_digest(edited, {}, {}, {}, [], {}) != digest, "Stat changes alter gameplay identity")
	edited = gameplay.duplicate(true)
	edited.evolutions[0].to = "c"
	expect(Identity.content_digest(edited, {}, {}, {}, [], {}) != digest, "Transition changes alter gameplay identity")
	edited = gameplay.duplicate(true)
	edited.forms[0].power_profile.damage = 3
	expect(Identity.content_digest(edited, {}, {}, {}, [], {}) != digest, "Power profile changes alter gameplay identity")
	expect(Migration.supported_legacy_target(Identity.current()), "Legacy adapter targets the current audited identity")
	var future_identity: Dictionary = Identity.current().duplicate(true)
	future_identity.content_sha256 = "future"
	expect(not Migration.supported_legacy_target(future_identity), "Changed gameplay catalog requires a migration decision")
	future_identity = Identity.current().duplicate(true)
	future_identity.ruleset = "future"
	expect(not Migration.supported_legacy_target(future_identity), "Changed ruleset requires a migration decision")
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/legacy_checkpoint_v1.json"))
	var migrated: Dictionary = Migration.checkpoint(legacy)
	expect(not migrated.is_empty() and migrated.schema == 2 and migrated.battle.party[0].form_id == "ember", "Frozen schema 1 checkpoint migrates to canonical form")
	expect(migrated.battle.rng_state == legacy.battle.rng_state and migrated.battle.seed_value == legacy.battle.seed_value and migrated.battle.enemy_plan == legacy.battle.enemy_plan and migrated.battle.hand == legacy.battle.hand and migrated.battle.party[0].cards == legacy.battle.party[0].cards and migrated.battle.party[0].passive == legacy.battle.party[0].passive, "Migration preserves RNG, plans, physical cards and passive")
	var legacy_reward: Dictionary = legacy.duplicate(true)
	legacy_reward.battle.reward_offers = [{"kind": "evolve", "uid": legacy_reward.battle.party[0].uid}]
	var migrated_reward: Dictionary = Migration.checkpoint(legacy_reward)
	expect(not migrated_reward.is_empty() and migrated_reward.battle.reward_offers[0].transition_id == "ember_to_ignivar" and migrated_reward.battle.reward_offers[0].source_form_id == "ember" and migrated_reward.battle.reward_offers[0].target_form_id == "ignivar", "Legacy pending evolution preserves the selected transition")
	var old_payload: Dictionary = {"schema": "umbral.expedition.checkpoint", "version": 1, "generation": 1, "kind": "snapshot", "snapshot": legacy}
	old_payload.checksum = JSON.stringify(JSON.parse_string(JSON.stringify(old_payload))).sha256_text()
	expect(Storage.write_json(PATH + ".0", KEY + ".0", old_payload), "Frozen legacy envelope written")
	expect(not store.load_snapshot().is_empty() and store.last_status == "ok", "Version 1 envelope remains readable")
	remove_fixtures()
	var run = Expedition.new()
	expect(run.restore(legacy), "Frozen legacy checkpoint restores")
	var prior: Dictionary = run.snapshot()
	for boundary in ["-9223372036854775808", "9223372036854775807"]:
		var extreme: Dictionary = prior.duplicate(true)
		extreme.battle.seed_value = boundary
		extreme.battle.rng_seed = boundary
		extreme.battle.rng_state = boundary
		expect(run.restore(extreme) and run.snapshot().battle.seed_value == boundary and run.snapshot().battle.rng_seed == boundary and run.snapshot().battle.rng_state == boundary, "Signed 64-bit boundary survives restore: " + boundary)
	expect(run.restore(prior), "Restore original run after boundary checks")
	for field in ["seed_value", "rng_seed", "rng_state"]:
		for invalid_number in ["9223372036854775808", "-9223372036854775809", " 1", "1 ", "1.0", "0x10"]:
			var malformed: Dictionary = prior.duplicate(true)
			malformed.battle[field] = invalid_number
			if field == "seed_value": malformed.battle.rng_seed = invalid_number
			if field == "rng_seed": malformed.battle.seed_value = invalid_number
			expect(not run.restore(malformed) and run.snapshot() == prior, "Invalid " + field + " is rejected without changing run: " + invalid_number)
	var foreign: Dictionary = prior.duplicate(true)
	foreign.identity.content_sha256 = "bad"
	expect(not run.restore(foreign) and run.snapshot() == prior, "Foreign identity cannot mutate live run")
	foreign = prior.duplicate(true)
	foreign.battle.party[0].form_id = "unknown"
	expect(not run.restore(foreign) and run.snapshot() == prior, "Unknown form cannot mutate live run")
	foreign = prior.duplicate(true)
	foreign.schema = 99
	expect(not run.restore(foreign) and run.snapshot() == prior, "Future snapshot schema rejected")
	var replay: Dictionary = Replay.envelope(prior, [])
	expect(not Replay.decode(replay).is_empty() and not Replay.decode({"initial_state": legacy, "commands": []}).is_empty(), "Versioned and legacy replays decode")
	replay.identity.ruleset = "future"
	expect(Replay.decode(replay).is_empty(), "Foreign replay rejected")
	print("Expedition save: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures else 0)
