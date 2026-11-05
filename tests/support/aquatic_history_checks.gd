extends RefCounted
## Expected rewards and continuations were recorded on untouched main, not authored here.
const Identity = preload("res://scripts/expedition/identity.gd")
const Registry = preload("res://scripts/expedition/migration_registry.gd")
const Migration = preload("res://scripts/expedition/migration.gd")
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Replay = preload("res://scripts/expedition/replay.gd")
const RunSave = preload("res://scripts/session/run_save.gd")
const Storage = preload("res://scripts/storage.gd")
const PATH: String = "user://aquatic_historical_reward_fixture.json"

static func current(source: Dictionary) -> Dictionary:
	var expected: Dictionary = source.duplicate(true)
	expected.identity = Identity.current()
	return expected

static func same(actual: Dictionary, expected: Dictionary) -> bool:
	return JSON.parse_string(JSON.stringify(actual)) == JSON.parse_string(JSON.stringify(expected))

static func run(expect: Callable) -> void:
	var history: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/combined_catalog4_main_reward_60b4e30.json"))
	var frozen: Dictionary = history.duplicate(true)
	expect.call(history.identity == Registry.COMBINED4_IDENTITY and history.source_commit == "60b4e3045ebb9188f2a1f67771a8f6bf37d714f9", "Pending reward originates from exact unchanged main catalog")
	var game = Expedition.new()
	expect.call(game.restore(history.initial_state) and Replay.execute(game, history.commands).ok, "Actual main commands reach the historical mixed-party reward")
	var expected: Dictionary = current(history.pending_reward)
	expect.call(same(game.snapshot(), expected), "Main reward preserves every field, offer order, RNG, cards and graph without aquatic finals")
	var migrated: Dictionary = Migration.checkpoint(history.pending_reward)
	expect.call(same(migrated, expected) and Migration.checkpoint(migrated) == migrated, "Historical pending reward migration is exact and idempotent")
	for suffix: String in [".0", ".1"]:
		if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	var store = RunSave.new(PATH, "test.aquatic.historical.reward")
	# A historical file has matching old identities in its envelope and snapshot.
	# Current writers receive migrated snapshots, as the production session does.
	var record: Dictionary = {"schema": RunSave.SCHEMA, "version": RunSave.VERSION, "generation": 1, "kind": "snapshot", "snapshot": history.pending_reward, "identity": history.identity}
	record.checksum = JSON.stringify(JSON.parse_string(JSON.stringify(record))).sha256_text()
	expect.call(Storage.write_json(PATH + ".0", "test.aquatic.historical.reward.0", record), "Historical main reward file has its matching original envelope and checksum")
	expect.call(game.restore(store.load_snapshot()) and same(game.snapshot(), expected), "Loading the pending reward preserves old choices after migration")
	for continuation: Dictionary in history.continuations:
		expect.call(game.restore(history.pending_reward), "Each historical choice starts at the unchanged main reward")
		expect.call(Replay.execute(game, continuation.commands.slice(0, 1)).ok and same(game.snapshot(), current(continuation.after_choice)), "Capture or evolution matches actual main outcome: " + str(continuation.index))
		expect.call(store.save(game.snapshot()), "Each historical choice persists through production save")
		var resumed = Expedition.new()
		expect.call(resumed.restore(store.load_snapshot()) and same(resumed.snapshot(), current(continuation.after_choice)), "Each historical choice resumes with exact individual state")
		expect.call(Replay.execute(resumed, continuation.commands.slice(1)).ok and same(resumed.snapshot(), current(continuation.after_next)), "Next encounter preserves actual main RNG, plans and cards: " + str(continuation.index))
	var before: Dictionary = game.snapshot()
	var forged: Dictionary = history.pending_reward.duplicate(true)
	forged.catalog_revision = 5
	expect.call(not game.restore(forged) and game.snapshot() == before, "Forged aquatic graph is rejected atomically without touching live reward state")
	expect.call(history == frozen, "Migration, replay and disk persistence never mutate the historical source fixture")
	expect.call(store.clear(), "Private historical reward save is removed after verification")
