extends SceneTree

const Content = preload("res://scripts/content.gd")
const Species = preload("res://scripts/catalog/species_resource.gd")
const Lookup = preload("res://scripts/catalog/lookup.gd")
const Evolution = preload("res://scripts/battle/evolution.gd")
const Progress = preload("res://scripts/codex_progress.gd")
var checks: int = 0
var failed: int = 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failed += 1
		push_error(label)

func _initialize() -> void:
	var fixture = Species.new()
	fixture.forms.assign([{"id": "seed"}, {"id": "oak"}, {"id": "pine"}, {"id": "ancient"}])
	fixture.evolutions.assign([{"id": "to_oak", "from": "seed", "to": "oak"}, {"id": "to_pine", "from": "seed", "to": "pine"}, {"id": "to_ancient", "from": "pine", "to": "ancient"}])
	var edges: Array = Lookup.edges(fixture, "seed")
	check(edges.map(func(e): return e.id) == ["to_oak", "to_pine"], "ordered branching")
	check(Lookup.edges(fixture, "oak").is_empty(), "terminal form")
	var individual: Dictionary = {"uid": 42, "form_id": "seed", "passive": "swift", "hp": 15, "max_hp": 40, "attack": 1, "defense": 1, "speed": 1, "known_powers": ["fireball"], "cards": [{"uid": 9, "owner_uid": 42, "power": "fireball"}]}
	var options: Array = Evolution.offers(individual, edges)
	check(options.size() == 2 and options[0].target_form_id == "oak" and options[1].target_form_id == "pine", "offer both branches in order")
	check(Evolution.valid(individual, options[1], edges), "second branch valid")
	var forged: Dictionary = options[1].duplicate(true)
	forged.target_form_id = "ancient"
	check(not Evolution.valid(individual, forged, edges), "reject forged target")
	var stale: Dictionary = options[1].duplicate(true)
	stale.source_form_id = "oak"
	check(not Evolution.valid(individual, stale, edges), "reject stale source")
	var cards: Array = individual.cards.duplicate(true)
	Evolution.apply(individual, "pine", {"max_hp": 80, "attack": 5, "defense": 3, "speed": 4})
	check(individual.form_id == "pine" and individual.hp == 30, "chosen branch and proportional HP")
	check(individual.uid == 42 and individual.passive == "swift" and individual.cards == cards and individual.known_powers == ["fireball"], "identity and cards preserved")
	check(not Evolution.valid(individual, options[1], edges), "reject offer after source changed")
	var next: Array = Evolution.offers(individual, Lookup.edges(fixture, individual.form_id))
	check(next.size() == 1 and next[0].target_form_id == "ancient", "multi-step offer")
	Evolution.apply(individual, "ancient", {"max_hp": 100, "attack": 6, "defense": 4, "speed": 5})
	check(Evolution.offers(individual, Lookup.edges(fixture, individual.form_id)).is_empty() and individual.hp == 38, "terminal form and HP rounding")
	var copy: Dictionary = Lookup.form(fixture, "seed")
	copy.id = "changed"
	check(fixture.forms[0].id == "seed", "fixture isolation")
	check(Progress.observed_form_ids({"species": "moss", "form_id": "branch"}, "seed") == ["seed", "branch"], "species ID cannot discover an unrelated form")
	check(Content.species_ids() == ["ember", "moss", "volt", "dew"], "manifest ordering")
	check(Content.form_ids("volt") == ["volt", "tempestral"], "form ordering")
	check(Content.display_name({"species": "volt", "form_id": "volt"}) == "Nisca", "approved electric starter uses its stable form ID")
	check(Content.display_name({"species": "volt", "form_id": "tempestral"}) == "Niscor", "approved electric evolution uses its stable form ID")
	check(Content.display_name({"species": "volt", "form_id": Content.legacy_form("volt", 1)}) == "Nisca" and Content.display_name({"species": "volt", "form_id": Content.legacy_form("volt", 2)}) == "Niscor", "explicit legacy migration mapping resolves approved names without new IDs")
	check(Content.evolution_edges({"species": "volt", "form_id": "volt"}) == [{"id": "volt_to_tempestral", "from": "volt", "to": "tempestral"}], "renaming preserves existing evolution offers and saved transition IDs")
	check(Progress.observed_form_ids({"species": "volt", "form_id": "tempestral"}, "volt") == ["volt", "tempestral"], "existing discovery IDs still reveal the renamed electric forms")
	var owner = {"species": "volt", "form_id": "tempestral"}
	check(Content.natures(owner) == ["lightning", "water"], "form natures")
	check(Content.power_stats("life_seed", owner).heal == 8, "learned power profile")
	var form = Content.form_definition("volt", "tempestral")
	form.stats.max_hp = 999
	check(Content.species_stats(owner).max_hp == 48, "catalog isolation")
	var lore: Dictionary = Content.form_definition("volt", "tempestral").lore
	var original_title: String = str(lore.title)
	lore.title = "changed"
	check(Content.form_definition("volt", "tempestral").lore.title == original_title and Content.UMBRAL_LORE.tempestral.title == original_title, "authored lore copy isolation")
	print(JSON.stringify({"suite": "catalog", "checks": checks, "failed": failed}))
	quit(1 if failed else 0)
