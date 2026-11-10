extends SceneTree
## Build presentation demand from actual Resources/APIs and supported save fixtures.
const Content = preload("res://scripts/content.gd")
const Expedition = preload("res://scripts/expedition/expedition.gd")
var entries: Dictionary = {}
var forms: Dictionary = {}
var enemies: Dictionary = {}
var compatibility: Array = []
var failures: Array = []

func add(species: String, form: String, power: String, reason: String) -> void:
	var key: String = "/".join([species, form, power])
	if not entries.has(key): entries[key] = {"species_id": species, "form_id": form, "power_id": power, "nature": Content.POWERS[power].nature, "reasons": []}
	if not reason in entries[key].reasons: entries[key].reasons.append(reason)

func retained_closure() -> void:
	var changed: bool = true
	while changed:
		var count: int = entries.size()
		for species: String in Content.species_ids():
			for edge: Dictionary in Content.CATALOG[species].evolutions:
				for entry: Dictionary in entries.values():
					if entry.species_id == species and entry.form_id == str(edge.from): add(species, str(edge.to), entry.power_id, "retained_from:" + str(edge.from))
		changed = entries.size() != count

func collect_checkpoint(value: Variant, source: String) -> void:
	if value is Dictionary:
		if value.has("battle") and value.has("current_node_id") and value.has("schema"):
			var run = Expedition.new()
			if not run.restore(value):
				failures.append("Unsupported compatibility fixture: " + source)
				return
			compatibility.append(source)
			for owner: Dictionary in run.battle.party:
				for card: Dictionary in owner.cards: add(str(owner.species), Content.form_id(owner), str(card.power), "compatibility:" + source)
			return
		for key: String in value: collect_checkpoint(value[key], source + "/" + key)
	elif value is Array:
		for index in value.size(): collect_checkpoint(value[index], source + "/" + str(index))

func _init() -> void:
	for species: String in Content.species_ids():
		var reachable: Array = [Content.initial_form(species)]
		var changed: bool = true
		while changed:
			changed = false
			for edge: Dictionary in Content.CATALOG[species].evolutions:
				if str(edge.from) in reachable and not str(edge.to) in reachable:
					reachable.append(str(edge.to))
					changed = true
		for form: String in Content.form_ids(species):
			forms[form] = {"species_id": species, "name": Content.form_definition(species, form).name, "reachable": form in reachable}
			if not form in reachable: continue
			for power: String in Content.initial_power_ids(species): add(species, form, power, "initial")
			for power: String in Content.POWERS:
				if Content.can_learn({"species": species, "form_id": form}, power): add(species, form, power, "learnable")
	for encounter: Dictionary in Content.ENCOUNTERS:
		for enemy: Dictionary in encounter.enemies:
			# Enemy form IDs can alias species forms; their public art binding is distinct.
			enemies[str(enemy.art)] = {"name": enemy.name, "art_binding": enemy.art}
	retained_closure()
	if "--compatibility" in OS.get_cmdline_user_args():
		for filename: String in DirAccess.get_files_at("res://tests/fixtures"):
			if filename.ends_with(".json"):
				var path: String = "res://tests/fixtures/" + filename
				collect_checkpoint(JSON.parse_string(FileAccess.get_file_as_string(path)), filename)
		retained_closure()
	var rows: Array = []
	var keys: Array = entries.keys()
	keys.sort()
	for key: String in keys:
		entries[key].reasons.sort()
		rows.append(entries[key])
	compatibility.sort()
	print(JSON.stringify({"schema_version": 1, "entries": rows, "forms": forms, "enemy_portraits": enemies, "natures": Content.NATURES.keys(), "compatibility_fixtures": compatibility, "errors": failures}))
	quit(0 if failures.is_empty() else 1)
