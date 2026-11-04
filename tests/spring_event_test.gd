extends SceneTree
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Practice = preload("res://scripts/battle/technique_practice.gd")
const Rules = preload("res://scripts/rules.gd")
const Replay = preload("res://scripts/expedition/replay.gd")
const Migration = preload("res://scripts/expedition/migration.gd")
const Identity = preload("res://scripts/expedition/identity.gd")
const Registry = preload("res://scripts/expedition/migration_registry.gd")
const Storage = preload("res://scripts/storage.gd")
const RunSave = preload("res://scripts/session/run_save.gd")
const Room = preload("res://scripts/ui/spring_room.gd")
var checks: int = 0
var failed: int = 0
var controls: Dictionary = {}
var emissions: Array = []

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func room_run() -> RefCounted:
	var expedition = Expedition.new()
	expedition.new_run(42013)
	expedition.battle.party.append(Rules.make_umbral("ember", "fierce", 2))
	expedition.battle.next_uid = 3
	expect(expedition.choose_node("clearing"), "Clearing entry")
	for enemy in expedition.battle.enemies: enemy.hp = 1
	for index in expedition.battle.best_selection(): expedition.battle.toggle(index)
	expect(expedition.battle.play().get("ok", false), "Real cast wins fixture battle")
	expedition.settle_battle()
	expect(expedition.phase == "reward" and not expedition.battle.reward_offers.any(func(offer): return offer.kind == "redistribute"), "Copy editing is absent from combat rewards")
	expect(expedition.choose_reward(1), "Resolve ordinary evolution before route choice")
	expedition.battle.party[0].hp = 12
	expect(expedition.choose_node("spring"), "Entering spring opens contextual room")
	return expedition

func rejected(expedition: RefCounted, choice: Dictionary, label: String) -> void:
	var before: Dictionary = expedition.snapshot()
	expect(not expedition.choose_event("practice", choice) and expedition.snapshot() == before, label)

func run() -> void:
	var expedition = room_run()
	var game: RefCounted = expedition.battle
	var before: Dictionary = expedition.snapshot()
	var first: Dictionary = game.party[0].duplicate(true)
	var powers: Array = first.known_powers
	var transfer: Dictionary = {"uid": 1, "from_power": powers[0], "to_power": powers[1]}
	expect(expedition.phase == "event" and game.phase == "map" and expedition.completed == ["clearing"], "Room is a stable state before spending the interval")
	expect(expedition.public_state().event.practice.size() == 2 and expedition.snapshot() == before, "Room preview is pure and includes healthy reserves")
	for invalid in [{}, {"uid": 999, "from_power": powers[0], "to_power": powers[1]}, {"uid": 1, "from_power": powers[0], "to_power": powers[0]}, {"uid": 1, "from_power": powers[0], "to_power": "unknown"}, {"uid": "1", "from_power": powers[0], "to_power": powers[1]}, {"uid": 1, "from_power": powers[0], "to_power": powers[1], "copies": 2}]:
		rejected(expedition, invalid, "Malformed or illegal practice is atomic: " + str(invalid))
	expect(not expedition.choose_event("shop") and not expedition.choose_event("rest", transfer) and expedition.snapshot() == before, "Unknown event and extra rest parameters are atomic")
	var restored = Expedition.new()
	expect(restored.restore(JSON.parse_string(JSON.stringify(before))) and restored.snapshot() == before, "Pending room survives exact JSON checkpoint")
	for field in ["event_revision", "phase", "current_node_id"]:
		var invalid: Dictionary = before.duplicate(true)
		invalid[field] = 99 if field == "event_revision" else "boss"
		expect(not restored.restore(invalid) and restored.snapshot() == before, "Invalid room field rejected atomically: " + field)
	var wrong_revision: Dictionary = before.duplicate(true)
	wrong_revision.event_revision = 0
	expect(not restored.restore(wrong_revision), "Legacy run cannot contain a new event")
	var store = RunSave.new("user://spring-test", "test.spring")
	expect(store.save(before), "Pending room can be checkpointed")
	expect(restored.restore(store.load_snapshot()) and restored.snapshot() == before, "Two-slot envelope restores pending room")
	expect(store.clear(), "Room test checkpoint cleaned")
	var replay: Dictionary = Replay.decode(Replay.envelope(before, [{"command": "event", "choice": "practice", "uid": 1, "from_power": powers[0], "to_power": powers[1]}]))
	expect(not replay.is_empty() and Replay.execute(restored, replay.commands).ok, "Whitelisted replay applies practice")
	expect(expedition.choose_event("practice", transfer), "Confirm exactly one copy transfer")
	expect(restored.snapshot() == expedition.snapshot(), "Restored event replay is identical")
	var after: Dictionary = game.party[0]
	expect(Practice.counts(after)[powers[0]] == 1 and Practice.counts(after)[powers[1]] == 3 and Practice.counts(after)[powers[2]] == 2, "Distribution changes from 2/2/2 to 1/3/2")
	expect(after.cards.size() == first.cards.size() and after.cards.map(func(card): return card.instance_id) == first.cards.map(func(card): return card.instance_id), "Total and physical instance IDs are conserved")
	expect(after.cards.all(func(card): return card.owner == 1) and after.uid == first.uid and after.passive == first.passive and after.form_id == first.form_id and after.known_powers == first.known_powers, "Owner, individual identity and known techniques are preserved")
	expect(after.hp == first.hp and game.party[1] == before.battle.party[1], "Practice grants no heal and cannot edit the other copy of the species")
	expect(str(game.rng.state) == before.battle.rng_state and expedition.phase == "map" and expedition.completed == ["clearing", "spring"], "Practice consumes the room once without RNG")
	var finished: Dictionary = expedition.snapshot()
	expect(not expedition.choose_event("rest") and not expedition.choose_node("thicket") and expedition.snapshot() == finished, "Cannot also heal or take the declined route")
	var replay_invalid: Dictionary = Replay.execute(expedition, [{"command": "event", "choice": "rest"}])
	expect(not replay_invalid.ok and replay_invalid.failed_index == 0 and expedition.snapshot() == finished, "Repeated replay command is atomic")
	expect(not Practice.valid(game.party, transfer), "Source minimum and target maximum stop repeated frequency concentration")
	expect(not Practice.valid(game.party, {"uid": 1, "from_power": powers[2], "to_power": powers[1]}), "Target capped at three even with a legal donor")
	var ko: Array = game.party.duplicate(true)
	ko[0].hp = 0
	expect(not Practice.valid(ko, {"uid": 1, "from_power": powers[1], "to_power": powers[0]}), "Incapacitated individuals cannot practice")
	expect(expedition.choose_node("boss"), "Boss remains accessible")
	expect(Practice.counts(game.party[0]) == Practice.counts(after), "Next encounter retains edited copies")
	var physical: Array = game.hand + game.deck + game.discard_pile
	for zone in game.suspended_cards.values(): physical += zone.deck + zone.discard
	expect(physical.size() == 12 and physical.filter(func(card): return card.owner == 1 and card.power == powers[1]).size() == 3, "Next active and reserve zones conserve edited instance collection")
	var rested = Expedition.new()
	expect(rested.restore(before) and rested.choose_event("rest"), "Explicit rest alternative")
	expect(rested.battle.party[0].hp == 12 + ceili(first.max_hp * 0.25) and rested.battle.party[0].cards == first.cards and str(rested.battle.rng.state) == before.battle.rng_state, "Rest heals 25 percent without copy edits or RNG")
	var frozen: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/expedition_rules2_replay.json"))
	var old = Expedition.new()
	var old_source: Dictionary = frozen.replay.initial_state.duplicate(true)
	expect(old.restore(old_source) and old.event_revision == 0 and old_source == frozen.replay.initial_state, "Previous main migrates on a detached copy, with legacy behavior pinned")
	var old_replay: Dictionary = Replay.decode(frozen.replay)
	var expected = Expedition.new()
	expect(expected.restore(frozen.expected), "Frozen final checkpoint validates and normalizes JSON number types")
	expect(not old_replay.is_empty() and Replay.execute(old, old_replay.commands).ok and old.snapshot() == expected.snapshot(), "Frozen main commands preserve rewards, hands, plans and exact RNG through two encounters")
	expect(expected.restore(frozen.rest_expected), "Frozen rest checkpoint validates")
	expect(old.restore(frozen.pending_reward) and old.choose_reward(1) and old.choose_node("spring") and old.phase == "map" and old.snapshot() == expected.snapshot(), "Previous main's immediate rest and final state remain exact")
	var forged: Dictionary = frozen.pending_reward.duplicate(true)
	forged.event_revision = 1
	expect(not old.restore(forged), "Old identity cannot forge an opt-in to event behavior")
	old.new_run(42013)
	expect(old.event_revision == 1, "New expedition gets the new room after a legacy resume")
	await ui_checks(before, transfer)
	print(JSON.stringify({"suite": "spring_event", "checks": checks, "failed": failed}))
	quit(1 if failed else 0)

func ui_checks(before: Dictionary, transfer: Dictionary) -> void:
	var expedition = Expedition.new()
	expect(expedition.restore(before), "Room UI fixture restores")
	var room = Room.new()
	room.populate(expedition.public_state(), 1.12)
	room.control_created.connect(func(control: Control, id: String): controls[id] = control)
	room.event_requested.connect(func(choice: String, details: Dictionary): emissions.append({"choice": choice, "details": details}))
	root.add_child(room)
	room.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	expect(controls["event.confirm"].disabled, "Room has no implicit default commitment")
	controls["event.practice"].pressed.emit()
	await process_frame
	controls["event.uid.1"].pressed.emit()
	await process_frame
	controls["event.from_power." + transfer.from_power].pressed.emit()
	await process_frame
	controls["event.to_power." + transfer.to_power].pressed.emit()
	await process_frame
	expect(not controls["event.confirm"].disabled and emissions.is_empty() and expedition.snapshot() == before, "Complete practice draft is pure until confirmation")
	controls["event.cancel"].pressed.emit()
	await process_frame
	expect(room.draft.is_empty() and room.choice.is_empty() and controls["event.confirm"].disabled and emissions.is_empty() and expedition.snapshot() == before, "Cancel discards draft without signals, save or RNG changes")
	controls["event.rest"].pressed.emit()
	await process_frame
	controls["event.confirm"].pressed.emit()
	expect(emissions == [{"choice": "rest", "details": {}}] and expedition.snapshot() == before, "View emits intent and never mutates the run")
	room.queue_free()
	await process_frame
