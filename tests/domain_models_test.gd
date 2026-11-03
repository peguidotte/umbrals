extends SceneTree
const Rules = preload("res://scripts/rules.gd")
const Individual = preload("res://scripts/domain/models/individual.gd")
const Card = preload("res://scripts/domain/models/card_instance.gd")
const Command = preload("res://scripts/domain/models/battle_command.gd")
const Event = preload("res://scripts/domain/models/battle_event.gd")
const Initiative = preload("res://scripts/battle/initiative.gd")
const EnemyPlanner = preload("res://scripts/battle/enemy_planner.gd")

var checks: int = 0
var failed: int = 0

func expect(ok: bool) -> void:
	checks += 1
	if not ok:
		failed += 1
		printerr("domain model check failed: %d" % checks)

func _initialize() -> void:
	var unit: Dictionary = Rules.make_umbral("ember", "fierce", 17)
	var parsed: Dictionary = Individual.try_from_dict(unit)
	expect(parsed.ok and parsed.value.uid == 17 and parsed.value.to_dict() == unit)
	var detached: Dictionary = parsed.value.to_dict()
	detached.cards[0].power = "changed"
	expect(parsed.value.to_dict() == unit)
	var bad: Dictionary = unit.duplicate(true)
	bad.hp = "1"
	expect(not Individual.try_from_dict(bad).ok)
	bad = unit.duplicate(true)
	bad.erase("speed")
	bad.speeed = 2
	expect(not Individual.try_from_dict(bad).ok)
	bad = unit.duplicate(true)
	bad.cards[0].owner = 18
	expect(not Individual.try_from_dict(bad).ok)
	bad = unit.duplicate(true)
	bad.cards[1].instance_id = bad.cards[0].instance_id
	expect(not Individual.try_from_dict(bad).ok)
	expect(Card.try_from_dict(unit.cards[0]).value.to_dict() == unit.cards[0])
	var command: Dictionary = {"kind": "power", "side": "ally", "actor_uid": 17, "actor_slot": 1, "priority": 0, "speed": 2, "key": "test", "card": unit.cards[0]}
	expect(Command.try_from_dict(command).value.to_dict() == command)
	var deploy: Dictionary = {"kind": "swap", "side": "ally", "actor_uid": -1, "actor_slot": 1, "priority": 100, "speed": 0, "key": "ally:swap:1", "swap": {"out_uid": -1, "in_uid": 17, "slot": 1}}
	expect(Command.try_from_dict(deploy).ok)
	for invalid_payload in [{}, {"slot": 1, "out_uid": -1}, {"slot": 2, "out_uid": -1, "in_uid": 17}, {"slot": 1, "out_uid": 8, "in_uid": 17}]:
		var invalid: Dictionary = deploy.duplicate(true)
		invalid.swap = invalid_payload
		expect(not Command.try_from_dict(invalid).ok)
	var item: Dictionary = {"kind": "item", "side": "ally", "actor_uid": -1, "actor_slot": -1, "priority": 90, "speed": 0, "key": "item", "item_index": 0, "order": {"item": "potion", "uid": 17}}
	expect(Command.try_from_dict(item).ok)
	for invalid_payload in [{}, {"item": "potion"}, {"item": "", "uid": 17}, {"item": "potion", "uid": "17"}]:
		var invalid: Dictionary = item.duplicate(true)
		invalid.order = invalid_payload
		expect(not Command.try_from_dict(invalid).ok)
	var game = Rules.new()
	game.new_run(123)
	for encounter_index in range(3):
		game.encounter = encounter_index
		game.start_encounter()
		for round_index in range(1, 4):
			var plans: Array = EnemyPlanner.build(game.enemies, game.party, round_index, game.rng)
			var queue: Array = Initiative.commit([], plans, game.enemies, game.rng)
			for entry in queue:
				expect(Command.try_from_dict(entry).ok)
				var invalid: Dictionary = entry.duplicate(true)
				invalid.intent = {}
				expect(not Command.try_from_dict(invalid).ok)
				invalid = entry.duplicate(true)
				invalid.intent.conditions = {"burn": "bad"}
				expect(not Command.try_from_dict(invalid).ok)
	command.actor_uid = 18
	expect(not Command.try_from_dict(command).ok)
	var event: Dictionary = {"kind": "attack", "actor_uid": 17, "actor_side": "ally", "actor_slot": 1, "target_uid": 20, "target_side": "enemy", "target_slot": 1, "power": "test", "amount": 2, "actor_name": "A", "target_name": "B", "target_state": {"hp": 2}}
	expect(Event.try_from_dict(event).value.to_dict() == event)
	event.target_slot = "one"
	expect(not Event.try_from_dict(event).ok)
	print(JSON.stringify({"suite": "domain_models", "checks": checks, "failed": failed}))
	quit(1 if failed else 0)
