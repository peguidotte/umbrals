extends RefCounted
## Frozen pre-change commands are the oracle, not a second implementation.
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Rules = preload("res://scripts/rules.gd")
const Content = preload("res://scripts/content.gd")
const Revision = preload("res://scripts/battle/catalog_revision.gd")
const Identity = preload("res://scripts/expedition/identity.gd")
const Registry = preload("res://scripts/expedition/migration_registry.gd")
const Previous = preload("res://scripts/expedition/rules2_manifest.gd")
const Migration = preload("res://scripts/expedition/migration.gd")
const Replay = preload("res://scripts/expedition/replay.gd")
const RunSave = preload("res://scripts/session/run_save.gd")
const Storage = preload("res://scripts/storage.gd")
const PATH = "user://grass_catalog_save_fixture"
const KEY = "test.grass.catalog"

static func fixture(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/" + name + ".json"))

static func cards_by_id(cards: Array) -> Dictionary:
	var result: Dictionary = {}
	for card in cards:
		var owned: Dictionary = card.duplicate(true)
		owned.erase("target_slot")
		result[card.instance_id] = owned
	return result

static func run(expect: Callable) -> void:
	var frozen: Dictionary = fixture("expedition_rules3_moss_replay")
	var old = Expedition.new()
	var expected = Expedition.new()
	var original: Dictionary = frozen.replay.initial_state.duplicate(true)
	expect.call(Registry.supports(original.identity) and JSON.stringify(Previous.DATA).sha256_text() == original.identity.content_sha256, "Rules-3 source has a frozen matching gameplay manifest")
	expect.call(old.restore(original) and original == frozen.replay.initial_state, "Rules-3 migration leaves its source untouched")
	expect.call(old.battle.catalog_revision == 0 and old.event_revision == 1, "Rules-3 retains spring behavior and the historical catalog")
	var migrated: Dictionary = old.snapshot()
	expect.call(Migration.checkpoint(migrated) == migrated, "Catalog migration is idempotent")
	var decoded: Dictionary = Replay.decode(frozen.replay)
	expect.call(not decoded.is_empty() and decoded.initial_state.catalog_revision == 0, "Frozen rules-3 replay decodes with historical catalog")
	if decoded.is_empty(): return
	expect.call(expected.restore(frozen.expected), "Frozen rules-3 second reward validates")
	expect.call(Replay.execute(old, decoded.commands).ok and old.snapshot() == expected.snapshot(), "59 original commands preserve full second reward, RNG, plans and physical cards")
	expect.call(old.battle.party[0].form_id == "verdalio" and old.battle.reward_offers.size() == 1, "Historical Folife receives no final-form evolution")
	expect.call(expected.restore(frozen.spring_expected) and old.restore(frozen.spring_replay.initial_state) and Replay.execute(old, frozen.spring_replay.commands).ok and old.snapshot() == expected.snapshot(), "Rules-3 spring commands retain the complete event-revision-1 result")
	var previous_sources: Array = [fixture("legacy_checkpoint_v1"), fixture("expedition_schema2_6e1b2ed"), fixture("expedition_rules2_replay").replay.initial_state]
	for source in previous_sources:
		var upgraded: Dictionary = Migration.checkpoint(source)
		expect.call(not upgraded.is_empty() and upgraded.catalog_revision == 0 and upgraded.event_revision == 0 and old.restore(upgraded), "Schema-1/rules-2 migration retains both historical revisions")
		expect.call(Migration.checkpoint(upgraded) == upgraded, "Historical migration remains idempotent")
	var old_spring_zero: Dictionary = frozen.pending_reward.duplicate(true)
	old_spring_zero.event_revision = 0
	expect.call(old.restore(old_spring_zero) and old.battle.catalog_revision == 0 and old.event_revision == 0 and old.choose_reward(1) and old.choose_node("spring") and old.phase == "map", "Rules-3 revision-0 branch keeps immediate spring behavior")
	new_evolution(frozen, expect)
	source_revision_checks(frozen, expect)
	rejections(frozen, expect)
	manifest_checks(expect)
	storage_checks(frozen, expect)

static func new_evolution(frozen: Dictionary, expect: Callable) -> void:
	var run = Expedition.new()
	run.new_run(1, "partial", "moss")
	expect.call(run.battle.catalog_revision == 1 and run.event_revision == 1, "New run selects catalog 1 independently of the spring revision")
	expect.call(Replay.execute(run, frozen.replay.commands).ok, "Real original commands reach new-run second reward")
	var before: Dictionary = run.snapshot()
	var historical = Expedition.new()
	historical.restore(frozen.expected)
	var old_rewards: Dictionary = historical.snapshot().battle
	expect.call(before.battle.rng_state == old_rewards.rng_state and before.battle.party == old_rewards.party and before.battle.hand == old_rewards.hand and before.battle.enemy_plan == old_rewards.enemy_plan, "New evolution availability adds no RNG, combat or card changes")
	var offer: Dictionary = {"kind": "evolve", "uid": 1, "source_form_id": "verdalio", "target_form_id": "foslash", "transition_id": "verdalio_to_foslash"}
	expect.call(run.battle.reward_offers.size() == 2 and run.battle.reward_offers[1] == offer, "Foslash is an explicit post-Folife reward choice")
	var owner: Dictionary = run.battle.party[0].duplicate(true)
	expect.call(Revision.edges(owner, 0).is_empty() and Revision.edges(owner, 1).size() == 1 and Revision.edges(owner, 2).is_empty(), "Revision query controls outgoing edges and fails closed for unknown revision")
	var resumed = Expedition.new()
	expect.call(resumed.restore(JSON.parse_string(JSON.stringify(before))) and resumed.snapshot() == before, "Pending new evolution survives exact JSON checkpoint")
	expect.call(run.choose_reward(1) and resumed.choose_reward(1) and resumed.snapshot() == run.snapshot(), "Actual Foslash choice executes identically after resume")
	var after: Dictionary = run.battle.party[0]
	expect.call(after.form_id == "foslash" and after.uid == owner.uid and after.passive == owner.passive and after.hp == ceili(float(after.max_hp) * float(owner.hp) / float(owner.max_hp)) and cards_by_id(after.cards) == cards_by_id(owner.cards) and after.known_powers == owner.known_powers, "Foslash keeps UID, passive, HP proportion, learned powers and every owned copy")
	for field in ["nature", "secondary_nature", "resistances", "trait_id"]:
		expect.call(Content.form_definition("moss", "foslash")[field] == Content.form_definition("moss", "verdalio")[field], "Final form explicitly inherits Folife prototype field: " + field)
	var final_form: Dictionary = Content.form_definition("moss", "foslash")
	expect.call(final_form.stats == {"max_hp": 72, "attack": 14, "defense": 6, "speed": 12}, "Foslash repeats the existing provisional attribute delta")
	expect.call(final_form.trait_value == 6, "Foslash repeats the existing living_roots delta")
	expect.call(final_form.power_profile == {"damage": 10, "block": 8, "heal": 4, "burn": 2, "wet": 2}, "Existing power copies receive the provisional profile increase")
	var old_lash: Dictionary = Content.power_stats("thorn_lash", owner)
	var final_lash: Dictionary = Content.power_stats("thorn_lash", after)
	expect.call(final_lash.damage == old_lash.damage + 5 and final_lash.block == old_lash.block + 4, "The same owned thorn_lash copies gain damage and block after evolution")
	expect.call(Revision.edges(after, 1).is_empty() and after.cards.size() == owner.cards.size(), "Final form adds no evolution or automatic signature copies")
	expect.call(resumed.restore(run.snapshot()) and resumed.battle.catalog_revision == 1 and resumed.battle.party[0].form_id == "foslash", "Chosen final form and catalog revision persist")
	expect.call(run.choose_node("boss") and run.battle.party[0].form_id == "foslash", "Chosen final form enters the next actual encounter")
	var wounded = Expedition.new()
	wounded.restore(before)
	wounded.battle.party[0].hp = 17
	expect.call(resumed.restore(wounded.snapshot()) and resumed.choose_reward(1) and resumed.battle.party[0].hp == 21, "Validated wounded fixture scales HP proportion from17/60 to21/72 without a free heal")
	resumed.restore(frozen.expected)
	resumed.new_run(1, "partial", "moss")
	expect.call(resumed.battle.catalog_revision == 1, "Starting anew after legacy resume resets catalog revision")

static func source_revision_checks(frozen: Dictionary, expect: Callable) -> void:
	for field in ["event_revision", "catalog_revision"]:
		var valid_values: Array = [0, 0.0, 1, 1.0] if field == "event_revision" else [0, 0.0]
		for value in valid_values:
			var source: Dictionary = frozen.replay.duplicate(true)
			source.initial_state[field] = value
			expect.call(not Migration.checkpoint(source.initial_state).is_empty() and not Replay.decode(source).is_empty(), "Historical numeric revision survives direct/JSON replay boundary: " + field + "=" + str(value))
		var invalid_values: Array = [-1, 2, 0.5, true, false, "0", null]
		if field == "catalog_revision": invalid_values.append(1)
		for value in invalid_values:
			var source: Dictionary = frozen.replay.duplicate(true)
			source.initial_state[field] = value
			expect.call(Migration.checkpoint(source.initial_state).is_empty() and Replay.decode(source).is_empty(), "Historical malformed revision is rejected before migration can overwrite it: " + field + "=" + str(value))

static func rejections(frozen: Dictionary, expect: Callable) -> void:
	var run = Expedition.new()
	run.restore(frozen.expected)
	var before: Dictionary = run.snapshot()
	for revision in [-1, 2, 1.5, "1", true, null]:
		var bad: Dictionary = before.duplicate(true)
		bad.catalog_revision = revision
		expect.call(not run.restore(bad) and run.snapshot() == before, "Unsupported or malformed catalog revision is atomic: " + str(revision))
	var bad: Dictionary = before.duplicate(true)
	bad.erase("catalog_revision")
	expect.call(not run.restore(bad) and run.snapshot() == before, "Rules-4 cannot omit the catalog revision")
	bad = frozen.expected.duplicate(true)
	bad.catalog_revision = 1
	expect.call(not run.restore(bad) and run.snapshot() == before, "Historical identity cannot opt into a new catalog")
	for identity in [before.identity, frozen.expected.identity]:
		bad = before.duplicate(true)
		bad.identity = identity.duplicate(true)
		bad.battle.party[0].form_id = "foslash"
		expect.call(not run.restore(bad) and run.snapshot() == before, "Historical catalog rejects forged final body: " + str(identity.ruleset))
		bad = before.duplicate(true)
		bad.identity = identity.duplicate(true)
		bad.battle.reward_offers[0].umbral = Rules.make_umbral("moss", "swift", int(bad.battle.next_uid), "foslash")
		expect.call(not run.restore(bad) and run.snapshot() == before, "Historical catalog rejects forged final capture")
		bad = before.duplicate(true)
		bad.identity = identity.duplicate(true)
		bad.battle.enemies[1].form_id = "foslash"
		expect.call(not run.restore(bad) and run.snapshot() == before, "Historical catalog rejects forged final enemy")
	var offer: Dictionary = {"kind": "evolve", "uid": 1, "source_form_id": "verdalio", "target_form_id": "foslash", "transition_id": "verdalio_to_foslash"}
	bad = before.duplicate(true)
	bad.battle.reward_offers.append(offer)
	expect.call(not run.restore(bad) and run.snapshot() == before, "Historical catalog rejects a forged pending final edge")
	run.battle.reward_offers.append(offer)
	var injected: Dictionary = run.snapshot()
	expect.call(not run.battle.choose_reward(1) and run.snapshot() == injected, "Live command revalidates revision before spending a reward")
	run.restore(before)
	var commands: Dictionary = Replay.execute(run, [{"command": "reward", "index": 1}])
	expect.call(not commands.ok and commands.failed_index == 0 and run.snapshot() == before, "Replay cannot choose an unavailable final reward")
	var mixed: Dictionary = frozen.replay.duplicate(true)
	mixed.identity = Identity.current()
	expect.call(Replay.decode(mixed).is_empty(), "Replay envelope cannot mix catalog lineage")
	bad = before.duplicate(true)
	bad.identity.content_sha256 = "unregistered-catalog"
	expect.call(not Registry.supports(bad.identity) and not run.restore(bad) and run.snapshot() == before, "Unknown catalog digest is rejected without live mutation")
	bad = fixture("expedition_rules2_replay").replay.initial_state.duplicate(true)
	bad.event_revision = 1
	expect.call(not run.restore(bad) and run.snapshot() == before, "Rules-2 cannot forge rules-3 spring behavior")

static func manifest_checks(expect: Callable) -> void:
	var target: Dictionary = Identity.manifest()
	expect.call(not Registry.additive(Previous.DATA, target) and Registry.catalog_transition(Previous.DATA, target), "Only the explicit reviewed catalog adapter admits final forms")
	var changed: Dictionary = target.duplicate(true)
	changed.catalog.moss.forms[1].stats.attack += 1
	expect.call(not Registry.catalog_transition(Previous.DATA, changed), "Adapter does not hide a changed historical form")
	changed = target.duplicate(true)
	changed.catalog.moss.evolutions[0].to = "foslash"
	expect.call(not Registry.catalog_transition(Previous.DATA, changed), "Adapter does not hide a changed historical edge")
	changed = target.duplicate(true)
	changed.catalog.moss.forms.back().catalog_revision = 0
	expect.call(not Registry.catalog_transition(Previous.DATA, changed), "Adapter requires the exact introduction revision")
	changed = target.duplicate(true)
	changed.catalog.moss.evolutions.back().id = "unreviewed_edge"
	expect.call(not Registry.catalog_transition(Previous.DATA, changed), "Adapter does not admit unregistered final transitions")
	changed = target.duplicate(true)
	changed.catalog.moss.forms.reverse()
	expect.call(not Registry.catalog_transition(Previous.DATA, changed), "Adapter requires explicit appended form ordering")

static func storage_checks(frozen: Dictionary, expect: Callable) -> void:
	for suffix in [".0", ".1", ".0.tmp", ".1.tmp"]:
		if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
	var store = RunSave.new(PATH, KEY)
	var original: Dictionary = fixture("expedition_rules3_moss_checkpoint")
	expect.call(Storage.write_json(PATH + ".0", KEY + ".0", original), "Real pre-change rules-3 envelope written to private fixture path")
	var loaded: Dictionary = store.load_snapshot()
	expect.call(not loaded.is_empty() and store.last_status == "ok", "Real rules-3 checksum envelope remains readable")
	var run = Expedition.new()
	expect.call(run.restore(loaded) and run.battle.catalog_revision == 0 and run.event_revision == 1, "Stored rules-3 checkpoint retains both independent revisions")
	expect.call(JSON.stringify(Storage.read_json(PATH + ".0", KEY + ".0")) == JSON.stringify(original), "Reading migration does not rewrite the historical envelope")
	var unknown: Dictionary = original.duplicate(true)
	unknown.identity.content_sha256 = "unknown-source"
	unknown.snapshot.identity = unknown.identity.duplicate(true)
	unknown.erase("checksum")
	unknown.checksum = JSON.stringify(JSON.parse_string(JSON.stringify(unknown))).sha256_text()
	expect.call(Storage.write_json(PATH + ".0", KEY + ".0", unknown), "Checksum-valid unknown identity envelope written")
	expect.call(store.load_snapshot().is_empty() and store.last_status == "incompatible" and not store.save(run.snapshot()) and not store.clear(), "Unknown catalog prevents load, overwrite and clear")
	expect.call(JSON.stringify(Storage.read_json(PATH + ".0", KEY + ".0")) == JSON.stringify(unknown), "Blocked storage remains byte-equivalent JSON")
	var future: Dictionary = original.duplicate(true)
	future.identity = Identity.current()
	future.snapshot.identity = Identity.current()
	future.snapshot.catalog_revision = 2
	future.erase("checksum")
	future.checksum = JSON.stringify(JSON.parse_string(JSON.stringify(future))).sha256_text()
	expect.call(Storage.write_json(PATH + ".0", KEY + ".0", future), "Checksum-valid future catalog revision envelope written")
	var future_bytes: String = FileAccess.get_file_as_string(PATH + ".0")
	expect.call(store.load_snapshot().is_empty() and store.last_status == "incompatible" and not store.save(run.snapshot()) and not store.clear(), "Future catalog revision prevents load, overwrite and clear")
	expect.call(FileAccess.get_file_as_string(PATH + ".0") == future_bytes, "Future revision record remains byte-for-byte untouched")
	for suffix in [".0", ".1", ".0.tmp", ".1.tmp"]:
		if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
