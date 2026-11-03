extends SceneTree
const Rules = preload("res://scripts/rules.gd")
const Models = preload("res://scripts/domain/models.gd")
const Content = preload("res://scripts/content.gd")
const Catalog = preload("res://scripts/domain/catalog_validation.gd")
const Evolution = preload("res://scripts/catalog/evolution_definition.gd")
var checks: int = 0
var failed: int = 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func edge(id: String, target: String) -> Evolution:
	var result = Evolution.new()
	result.transition_id = id
	result.target_form_id = target
	return result

func fixture() -> Content.Species:
	var species: Content.Species = Content.SPECIES.ember.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	species.species_id = "fixture"
	species.initial_form_id = "seedling"
	var root = species.forms[0]
	root.form_id = "seedling"
	root.evolutions.assign([edge("grow", "middle")])
	var middle = species.forms[1]
	middle.form_id = "middle"
	middle.evolutions.assign([edge("bloom", "crown"), edge("scorch", "ashen")])
	middle.evolutions[0].health_cost = 2
	middle.evolutions[0].min_encounter = 1
	middle.evolutions[0].required_passive = "fierce"
	var crown: Content.Form = middle.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	crown.form_id = "crown"
	crown.evolutions.clear()
	crown.trait_strength = 9
	var healing = Content.SPECIES.moss.forms[0].power("life_seed").duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	healing.power_id = "fixture_healing"
	crown.powers.assign([healing])
	var ashen: Content.Form = middle.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	ashen.form_id = "ashen"
	ashen.evolutions.clear()
	ashen.trait_strength = 6
	species.forms.append_array([crown, ashen])
	return species

func clear_enemy(game: Rules) -> void:
	game.enemy_hp = 1
	game.hand.assign([Models.CardInstance.new("fireball", 88)])
	game.selected.assign([0])
	expect(game.play().ok, "Fixture clears an encounter using an owned power")

func _init() -> void:
	var species = fixture()
	expect(Catalog.validate(entries(species)).is_empty(), "Catalog accepts three levels and a branch with four stable form IDs")
	var broken: Content.Species = species.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	broken.forms[1].evolutions[0].target_form_id = "foreign_form"
	expect(not Catalog.validate(entries(broken)).is_empty(), "Cross-species/missing destinations are rejected")
	broken = species.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	broken.forms[2].evolutions.append(edge("back", "seedling"))
	expect(not Catalog.validate(entries(broken)).is_empty(), "Evolution cycles are rejected")
	broken = species.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	broken.forms[1].evolutions.remove_at(1)
	expect(not Catalog.validate(entries(broken)).is_empty(), "Unreachable forms are rejected")
	broken = species.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	broken.forms[2].form_id = "middle"
	expect(not Catalog.validate(entries(broken)).is_empty(), "Duplicate form IDs are rejected")
	var definitions = Content.create_catalog()
	definitions.species.fixture = species
	var game = Rules.new(definitions)
	game.new_run(42013)
	game.party.assign([definitions.make_individual("fixture", "fierce", 88)])
	game.start_encounter()
	expect(game.party[0].form_id == "seedling", "Creation resolves the declared initial form")
	clear_enemy(game)
	var before: Dictionary = game.snapshot()
	var rng_state: int = game.rng.state
	game.reward_offers[1].target_form_id = "missing"
	expect(not game.choose_reward(1), "A forged destination cannot change the individual")
	game.reward_offers[1].target_form_id = "middle"
	expect(game.snapshot() == before and game.rng.state == rng_state, "Rejected evolution preserves all state and randomness")
	expect(game.choose_reward(1) and game.party[0].form_id == "middle", "First transition reaches the intermediate form")
	expect(game.party[0].uid == 88 and game.party[0].passive == "fierce" and game.party[0].species_id == "fixture", "Evolution preserves individual identity, passive and species")
	clear_enemy(game)
	expect(game.reward_offers.size() == 3 and game.reward_offers[1].target_form_id == "crown" and game.reward_offers[2].target_form_id == "ashen", "Each eligible branch is a separate stable reward offer")
	game.player_hp = 2
	expect(not game.choose_reward(1) and game.player_hp == 2 and game.party[0].form_id == "middle", "Transition requirements are revalidated without spending health on rejection")
	game.player_hp = 10
	expect(game.choose_reward(1) and game.party[0].form_id == "crown" and game.player_hp == 16, "Second evolution charges its declared cost before capped reward healing")
	expect(game.hand.size() == 2 and game.deck.is_empty(), "The target explicitly replaces the former power set")
	for card in game.hand: expect(card.power == "fixture_healing" and card.owner == 88, "Released powers do not survive the rebuild")
	game.selected.assign([0])
	expect(game.preview().valid and game.preview().heal == 6, "New per-form powers work without editing any global power index")
	expect(definitions.form(game.party[0]).evolutions.is_empty(), "Terminal forms do not require a numeric max-stage convention")
	var alt = Rules.new(definitions)
	alt.new_run(5)
	alt.party.assign([definitions.make_individual("fixture", "fierce", 88, "middle")])
	alt.start_encounter()
	clear_enemy(alt)
	# Crown is unavailable in encounter zero; the other branch remains available.
	expect(alt.reward_offers.size() == 2 and alt.reward_offers[1].target_form_id == "ashen", "Eligibility filters each branch independently")
	expect(alt.choose_reward(1) and alt.party[0].form_id == "ashen", "The alternate branch can be chosen independently")
	print(JSON.stringify({"suite": "evolution_graph", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)

func entries(extra: Content.Species) -> Array[Content.Species]:
	var all: Array[Content.Species] = Content.DATABASE.species.duplicate()
	all.append(extra)
	return all
