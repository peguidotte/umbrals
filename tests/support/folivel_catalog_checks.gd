extends RefCounted
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Content = preload("res://scripts/content.gd")
const Rules = preload("res://scripts/rules.gd")
const Revision = preload("res://scripts/battle/catalog_revision.gd")
const Identity = preload("res://scripts/expedition/identity.gd")
const Registry = preload("res://scripts/expedition/migration_registry.gd")
const Catalog1 = preload("res://scripts/expedition/catalog1_manifest.gd")
const Migration = preload("res://scripts/expedition/migration.gd")
const Replay = preload("res://scripts/expedition/replay.gd")
const RunSave = preload("res://scripts/session/run_save.gd")
const Storage = preload("res://scripts/storage.gd")
const PATH = "user://folivel_catalog_save_fixture"
const KEY = "test.folivel.catalog"

static func fixture(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/" + name + ".json"))

static func copies(cards: Array) -> Dictionary:
	var result: Dictionary = {}
	for card in cards:
		var owned: Dictionary = card.duplicate(true)
		owned.erase("target_slot")
		result[card.instance_id] = owned
	return result

static func final_offer() -> Dictionary:
	return {"kind": "evolve", "uid": 1, "source_form_id": "verdalio", "target_form_id": "folivel", "transition_id": "verdalio_to_folivel"}

static func run(expect: Callable) -> void:
	var frozen: Dictionary = fixture("expedition_catalog1_moss_replays")
	expect.call(frozen.identity == Registry.CATALOG1_IDENTITY and JSON.stringify(Catalog1.DATA).sha256_text() == frozen.identity.content_sha256, "Committed catalog-1 identity has its exact frozen manifest")
	expect.call(Registry.supports(frozen.identity) and Registry.catalog_transition(Catalog1.DATA, Identity.manifest(), 1), "Catalog-1 source reaches the appended Folivel catalog through its reviewed adapter")
	for revision in [0, 1]:
		var recording: Dictionary = frozen["catalog%d_replay" % revision]
		var original: Dictionary = recording.initial_state.duplicate(true)
		var decoded: Dictionary = Replay.decode(recording)
		var old = Expedition.new()
		var expected = Expedition.new()
		expect.call(old.restore(original) and original == recording.initial_state and old.battle.catalog_revision == revision and old.event_revision == 1, "079 source preserves catalog revision and spring behavior: " + str(revision))
		expect.call(not decoded.is_empty(), "Frozen catalog-1 lineage replay decodes: " + str(revision))
		if decoded.is_empty(): continue
		expect.call(expected.restore(frozen["catalog%d_expected" % revision]), "Frozen catalog-1 expected state normalizes: " + str(revision))
		expect.call(Replay.execute(old, decoded.commands).ok and old.snapshot() == expected.snapshot(), "Real prior commands preserve complete RNG/plans/offers/cards/UID state: " + str(revision))
		var migrated: Dictionary = old.snapshot()
		expect.call(Migration.checkpoint(migrated) == migrated, "079 migration is idempotent: " + str(revision))
		if revision == 0: expect.call(old.battle.reward_offers.size() == 1, "079 catalog-0 keeps capture-only second reward")
		else: expect.call(old.battle.party[0].form_id == "foslash" and old.current_node_id == "boss", "079 catalog-1 retains its actual chosen Foslash and next battle")
	source_revisions(frozen, expect)
	new_folivel(frozen, expect)
	rejections(frozen, expect)
	manifest_checks(expect)
	storage_checks(expect)

static func source_revisions(frozen: Dictionary, expect: Callable) -> void:
	for value in [0, 0.0, 1, 1.0]:
		var source: Dictionary = frozen.catalog1_replay.duplicate(true)
		source.initial_state.catalog_revision = value
		expect.call(not Migration.checkpoint(source.initial_state).is_empty() and not Replay.decode(source).is_empty(), "079 accepts only its integral catalog revisions: " + str(value))
	for value in [-1, 2, 3, 0.5, true, false, "1", null]:
		var source: Dictionary = frozen.catalog1_replay.duplicate(true)
		source.initial_state.catalog_revision = value
		expect.call(Migration.checkpoint(source.initial_state).is_empty() and Replay.decode(source).is_empty(), "079 cannot forge catalog2 even with no new body: " + str(value))
	var missing: Dictionary = frozen.catalog1_replay.initial_state.duplicate(true)
	missing.erase("catalog_revision")
	expect.call(Migration.checkpoint(missing).is_empty(), "079 rules-4 requires the saved catalog field")
	for value in [0, 0.0, 1, 1.0]:
		var source: Dictionary = frozen.catalog1_replay.initial_state.duplicate(true)
		source.event_revision = value
		var migrated: Dictionary = Migration.checkpoint(source)
		expect.call(not migrated.is_empty() and migrated.event_revision == value and migrated.catalog_revision == 1, "079 retains both integral spring alternatives: " + str(value))

static func new_folivel(frozen: Dictionary, expect: Callable) -> void:
	var run = Expedition.new()
	run.new_run(1, "partial", "moss")
	var commands: Array = frozen.catalog0_replay.commands
	expect.call(run.battle.catalog_revision == Revision.CURRENT and Replay.execute(run, commands).ok, "New combined catalog follows the same 59 actual commands")
	var pending: Dictionary = run.snapshot()
	expect.call(run.phase == "reward" and run.current_node_id == "thicket" and run.battle.reward_offers.size() == 3 and run.battle.reward_offers[2] == final_offer(), "Folivel is the explicit second final branch after Folife")
	var previous = Expedition.new()
	previous.restore(frozen.catalog1_reward)
	var old_battle: Dictionary = previous.snapshot().battle
	var new_battle: Dictionary = pending.battle.duplicate(true)
	old_battle.erase("reward_offers")
	new_battle.erase("reward_offers")
	expect.call(old_battle == new_battle and run.battle.reward_offers.slice(0, 2) == previous.battle.reward_offers, "Adding Folivel changes only the appended offer, preserving all prior state and RNG")
	var owner: Dictionary = run.battle.party[0].duplicate(true)
	var resumed = Expedition.new()
	expect.call(resumed.restore(JSON.parse_string(JSON.stringify(pending))) and resumed.snapshot() == pending, "Pending Folivel choice restores exactly through JSON")
	expect.call(Revision.edges(owner, 0).is_empty() and Revision.edges(owner, 1).size() == 1 and Revision.edges(owner, 2).size() == 2, "Revision query exposes only the permitted branch set")
	expect.call(Replay.apply(run, {"command": "reward", "index": 2}) and resumed.choose_reward(2) and run.snapshot() == resumed.snapshot(), "Actual Folivel choice executes identically after resume")
	var after: Dictionary = run.battle.party[0]
	expect.call(after.form_id == "folivel" and after.uid == owner.uid and after.passive == owner.passive and after.hp == ceili(float(after.max_hp) * float(owner.hp) / float(owner.max_hp)) and copies(after.cards) == copies(owner.cards) and after.known_powers == owner.known_powers, "Folivel preserves individual identity, HP proportion and every owned power instance")
	for field in ["nature", "secondary_nature", "resistances", "trait_id", "trait_value", "stats", "power_profile"]:
		expect.call(Content.form_definition("moss", "folivel")[field] == Content.form_definition("moss", "foslash")[field], "Folivel shares the approved provisional numeric contract: " + field)
	expect.call(after.cards.size() == owner.cards.size() and Revision.edges(after, 2).is_empty(), "Final choice adds no automatic signature/cards or further evolution")
	expect.call(Replay.apply(run, {"command": "node", "id": "boss"}) and run.battle.party[0].form_id == "folivel", "Actual Folivel proceeds to the next encounter")
	var encoded: Dictionary = Replay.envelope(pending, [{"command": "reward", "index": 2}, {"command": "node", "id": "boss"}])
	var decoded: Dictionary = Replay.decode(JSON.parse_string(JSON.stringify(encoded)))
	expect.call(not decoded.is_empty() and resumed.restore(decoded.initial_state) and Replay.execute(resumed, decoded.commands).ok and resumed.snapshot() == run.snapshot(), "Current Folivel replay retains exact next-battle cards, plans and RNG")
	var wounded: Dictionary = pending.duplicate(true)
	wounded.battle.party[0].hp = 17
	expect.call(resumed.restore(wounded) and resumed.choose_reward(2) and resumed.battle.party[0].hp == 21, "Validated Folivel choice scales17/60 to21/72 without full healing")
	resumed.restore(frozen.catalog1_reward)
	resumed.new_run(1, "partial", "moss")
	expect.call(resumed.battle.catalog_revision == Revision.CURRENT, "Starting anew after catalog1 resume explicitly selects the current catalog")

static func rejections(frozen: Dictionary, expect: Callable) -> void:
	var run = Expedition.new()
	run.restore(frozen.catalog1_reward)
	var before: Dictionary = run.snapshot()
	for source in [before.identity, frozen.identity]:
		var forged: Dictionary = before.duplicate(true)
		forged.identity = source.duplicate(true)
		forged.battle.party[0].form_id = "folivel"
		expect.call(not run.restore(forged) and run.snapshot() == before, "Catalog1 rejects Folivel body under current/pinned source identity")
		forged = before.duplicate(true)
		forged.identity = source.duplicate(true)
		forged.battle.enemies[1].form_id = "folivel"
		expect.call(not run.restore(forged) and run.snapshot() == before, "Catalog1 rejects forged Folivel enemy")
		forged = before.duplicate(true)
		forged.identity = source.duplicate(true)
		forged.battle.reward_offers[0].umbral = Rules.make_umbral("moss", "swift", int(forged.battle.next_uid), "folivel")
		expect.call(not run.restore(forged) and run.snapshot() == before, "Catalog1 rejects forged Folivel capture")
		forged = before.duplicate(true)
		forged.identity = source.duplicate(true)
		forged.battle.reward_offers.append(final_offer())
		expect.call(not run.restore(forged) and run.snapshot() == before, "Catalog1 rejects forged pending Folivel transition")
	var forged_zero: Dictionary = frozen.catalog1_after_evolution.duplicate(true)
	forged_zero.catalog_revision = 0
	expect.call(not run.restore(forged_zero) and run.snapshot() == before, "Pinned079 catalog0 cannot smuggle the already-known Foslash body")
	run.battle.reward_offers.append(final_offer())
	var injected: Dictionary = run.snapshot()
	expect.call(not run.battle.choose_reward(2) and run.snapshot() == injected, "Command application revalidates catalog1 against a live injected Folivel offer")
	run.restore(before)
	var result: Dictionary = Replay.execute(run, [{"command": "reward", "index": 2}])
	expect.call(not result.ok and result.failed_index == 0 and run.snapshot() == before, "Pinned-catalog replay cannot inject the new reward index")

static func manifest_checks(expect: Callable) -> void:
	var target: Dictionary = Identity.manifest()
	var changed: Dictionary = target.duplicate(true)
	changed.catalog.moss.forms[2].stats.attack += 1
	expect.call(not Registry.catalog_transition(Catalog1.DATA, changed, 1), "Catalog2 adapter preserves every committed Foslash numeric definition")
	changed = target.duplicate(true)
	changed.catalog.moss.evolutions[1].to = "folivel"
	expect.call(not Registry.catalog_transition(Catalog1.DATA, changed, 1), "Catalog2 adapter cannot rewrite the committed Foslash edge")
	changed = target.duplicate(true)
	changed.catalog.moss.forms.back().catalog_revision = 1
	expect.call(not Registry.catalog_transition(Catalog1.DATA, changed, 1), "Registered Folivel suffix requires its exact introduction revision")
	changed = target.duplicate(true)
	changed.catalog.moss.forms.reverse()
	expect.call(not Registry.catalog_transition(Catalog1.DATA, changed, 1), "Catalog2 adapter rejects unreviewed form ordering")
	expect.call(not Registry.catalog_transition(Catalog1.DATA, target, 2), "Catalog1 cannot claim the catalog2 source projection")

static func storage_checks(expect: Callable) -> void:
	for suffix in [".0", ".1", ".0.tmp", ".1.tmp"]:
		if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	var store = RunSave.new(PATH, KEY)
	var original: Dictionary = fixture("expedition_catalog1_moss_checkpoint")
	expect.call(Storage.write_json(PATH + ".0", KEY + ".0", original), "Real committed catalog1 envelope written to private fixture storage")
	var bytes: String = FileAccess.get_file_as_string(PATH + ".0")
	var loaded: Dictionary = store.load_snapshot()
	var run = Expedition.new()
	expect.call(not loaded.is_empty() and store.last_status == "ok" and run.restore(loaded) and run.battle.catalog_revision == 1, "Pinned079 checksum envelope restores without upgrading catalog selection")
	expect.call(FileAccess.get_file_as_string(PATH + ".0") == bytes, "Reading committed catalog1 leaves original bytes untouched")
	var forged: Dictionary = original.duplicate(true)
	forged.snapshot.catalog_revision = 2
	forged.erase("checksum")
	forged.checksum = JSON.stringify(JSON.parse_string(JSON.stringify(forged))).sha256_text()
	expect.call(Storage.write_json(PATH + ".0", KEY + ".0", forged), "Checksum-valid079 catalog2 forgery written")
	bytes = FileAccess.get_file_as_string(PATH + ".0")
	expect.call(store.load_snapshot().is_empty() and store.last_status == "incompatible" and not store.save(run.snapshot()) and not store.clear(), "079 catalog2 forgery blocks load, overwrite and clear")
	expect.call(FileAccess.get_file_as_string(PATH + ".0") == bytes, "Forbidden079 catalog2 envelope remains byte-for-byte intact")
	for suffix in [".0", ".1", ".0.tmp", ".1.tmp"]:
		if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
