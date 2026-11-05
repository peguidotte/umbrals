extends SceneTree
const Identity = preload("res://scripts/expedition/identity.gd")
const Registry = preload("res://scripts/expedition/migration_registry.gd")
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Replay = preload("res://scripts/expedition/replay.gd")
var failures: int = 0
func check(value: bool, message: String) -> void:
 if not value:
  failures += 1
  printerr("FAIL: " + message)
func _initialize() -> void:
 var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/expedition_schema2_6e1b2ed.json"))
 if "--reject" in OS.get_cmdline_user_args():
  check(not Registry.supports(old.identity), "changed historical gameplay is rejected")
  var blocked = Expedition.new()
  check(not blocked.restore(old), "changed historical gameplay blocks restore")
  var bad: Dictionary = {"schema": Replay.SCHEMA, "version": Replay.VERSION, "identity": old.identity, "initial_state": old, "commands": []}
  check(Replay.decode(bad).is_empty(), "changed historical gameplay blocks replay")
  print("Incompatible integration failures: ", failures)
  quit(1 if failures else 0)
  return
 check(Registry.supports(old.identity) and old.identity != Identity.current(), "historical identity reaches expanded catalog")
 var a = Expedition.new()
 check(a.restore(old), "historical checkpoint restores with expanded content")
 var replay: Dictionary = {"schema": Replay.SCHEMA, "version": Replay.VERSION, "identity": old.identity, "initial_state": old, "commands": [{"command": "select", "index": 0}]}
 var decoded: Dictionary = Replay.decode(replay)
 check(not decoded.is_empty(), "historical replay decodes")
 var b = Expedition.new()
 check(not decoded.is_empty() and b.restore(decoded.get("initial_state", {})), "decoded checkpoint restores")
 var first: Dictionary = Replay.execute(a, replay.commands)
 var second: Dictionary = Replay.execute(b, replay.commands)
 check(first.ok and second.ok and first.snapshot == second.snapshot, "replay produces identical semantic state")
 var current: Dictionary = preload("res://scripts/expedition/migration.gd").checkpoint(old)
 current.identity = Identity.current()
 current.battle.party[0].species = "future_species"
 current.battle.party[0].known_powers[0] = "future_power"
 for card in current.battle.party[0].cards:
  if card.power == "fireball": card.power = "future_power"
 for zone in ["hand", "deck", "discard_pile"]:
  for card in current.battle[zone]:
   if card.power == "fireball": card.power = "future_power"
 current.battle.inventory["future_item"] = 1
 current.battle.party[0].hp = 20
 check(a.restore(current), "new species, power and item restore under current identity")
 check(not Replay.decode(Replay.envelope(current, [])).is_empty(), "new content replay decodes")
 check(a.battle.queue_item("future_item", 1), "new item effect queues")
 var power_index: int = -1
 for i in range(a.battle.hand.size()):
  if a.battle.hand[i].power == "future_power": power_index = i
 check(power_index >= 0 and a.battle.toggle(power_index), "new power participates in play")
 check(a.battle.play().get("ok", false) and a.battle.inventory.get("future_item") == 0, "new item resolves and is consumed")
 var forged: Dictionary = current.duplicate(true)
 forged.identity = old.identity
 check(not a.restore(forged), "historical identity rejects future definitions")
 var forged_replay: Dictionary = replay.duplicate(true)
 forged_replay.initial_state = forged
 check(Replay.decode(forged_replay).is_empty(), "historical replay rejects future definitions")
 forged_replay = replay.duplicate(true)
 forged_replay.identity = Identity.current()
 check(Replay.decode(forged_replay).is_empty(), "mixed replay lineage rejected")
 print("Additive integration failures: ", failures)
 quit(1 if failures else 0)
