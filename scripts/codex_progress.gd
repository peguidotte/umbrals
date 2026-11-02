class_name UmbralCodexProgress
extends RefCounted
## Additive knowledge only. Never changes a run, rule state or RNG.
const Content = preload("res://scripts/content.gd")
const Storage = preload("res://scripts/storage.gd")
const PATH = "user://umbral_codex_v1.json"
const KEY = "umbral.codex.v1"
var records: Dictionary = {"umbrals": {}, "powers": {}, "passives": {}, "items": {}}
var saved_ok: bool = true

func load_saved() -> void:
	var data: Dictionary = Storage.read_json(PATH, KEY)
	if int(data.get("version", 0)) != 1: return
	for category in records:
		if data.get(category) is Dictionary:
			for id in data[category]:
				if data[category][id] == true: records[category][str(id)] = true

func knows(category: String, id: String) -> bool:
	return records.get(category, {}).get(id, false) == true

func mark(category: String, id: String) -> bool:
	if id.is_empty() or knows(category, id): return false
	records[category][id] = true
	return true

func observe(game: RefCounted, include_enemies: bool = true) -> void:
	var changed: bool = false
	for individual in game.party:
		var species: String = str(individual.get("species", ""))
		if not Content.SPECIES.has(species): continue
		changed = mark("umbrals", species) or changed
		if int(individual.get("stage", 1)) > 1: changed = mark("umbrals", str(Content.SPECIES[species].art[1]).get_file()) or changed
		var passive: String = str(individual.get("passive", ""))
		if Content.PASSIVES.has(passive): changed = mark("passives", passive) or changed
		for power in individual.get("known_powers", []):
			if Content.POWERS.has(power): changed = mark("powers", str(power)) or changed
		for card in individual.get("cards", []):
			if Content.POWERS.has(card.get("power", "")): changed = mark("powers", str(card.power)) or changed
	if include_enemies:
		for enemy in game.enemies:
			var art: String = str(enemy.get("art", "")).get_file()
			if not art.is_empty(): changed = mark("umbrals", art) or changed
	for item in game.inventory:
		if int(game.inventory[item]) > 0 and Content.CONSUMABLES.has(item): changed = mark("items", str(item)) or changed
	if changed or not saved_ok: save()

func save() -> bool:
	var data = records.duplicate(true)
	data.version = 1
	saved_ok = Storage.write_json(PATH, KEY, data)
	if not saved_ok: push_warning("Grimório disponível nesta sessão; não foi possível salvar as descobertas.")
	return saved_ok
