extends SceneTree
const Models = preload("res://scripts/domain/models.gd")
const Rules = preload("res://scripts/rules.gd")
const Content = preload("res://scripts/content.gd")
const Ids = preload("res://scripts/domain/ids.gd")
const Catalog = preload("res://scripts/domain/catalog_validation.gd")
var checks: int = 0
var failed: int = 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func _init() -> void:
	expect(Catalog.validate(Content.DATABASE.species).is_empty(), "Shipped catalog satisfies references and mechanics contracts")
	var entries = _copy_species()
	entries[0].forms[0].evolutions[0].target_form_id = "missing"
	expect(not Catalog.validate(entries).is_empty(), "Unknown evolution destinations are rejected")
	entries = _copy_species()
	entries[0].forms[0].presentation.left = null
	expect(not Catalog.validate(entries).is_empty(), "Missing left direction is rejected")
	entries = _copy_species()
	entries[0].forms[0].presentation.right.clips.remove_at(0)
	expect(not Catalog.validate(entries).is_empty(), "Missing idle animation is rejected")
	entries = _copy_species()
	entries[0].passive_pool = PackedStringArray(["missing"])
	expect(not Catalog.validate(entries).is_empty(), "Unknown passive pool entries are rejected")
	var encounters: Array = []
	for encounter in Content.ENCOUNTERS: encounters.append(encounter.duplicate_deep(Resource.DEEP_DUPLICATE_ALL))
	encounters[0].enemy.actions.clear()
	expect(not Catalog.validate(Content.DATABASE.species, encounters).is_empty(), "Empty intention patterns are rejected")
	for species in Content.DATABASE.species:
		for shape in species.forms:
			expect(FileAccess.file_exists(shape.presentation.right.portrait_path), "Form portrait exists")
			for power in shape.powers: expect(FileAccess.file_exists(power.art_path), "Power art exists")
	for definition in Content.ENCOUNTERS: expect(FileAccess.file_exists("res://assets/%s.svg" % definition.art), "Encounter art exists")
	expect(Content.VERSION == ProjectSettings.get_setting("application/config/version"), "Game and project versions agree")
	var g = Rules.new()
	g.new_run(1)
	g.party.assign([Rules.make_umbral("moss", "vital", 1)])
	g.start_encounter()
	g.player_hp = 39
	g.hand.assign([Models.CardInstance.new("life_seed", 1)])
	g.selected.assign([0])
	var before: Dictionary = g.snapshot()
	var rng_state: int = g.rng.state
	var projection: Models.ResolutionResult = g.preview_round()
	expect(projection.effective_heal == 1 and projection.incoming == 7 and projection.player_hp_after == 33, "Projection caps healing before retaliation")
	expect(g.snapshot() == before and g.rng.state == rng_state, "Projection does not mutate state or randomness")
	g.play()
	expect(g.player_hp == projection.player_hp_after and g.enemy_hp == projection.enemy_hp_after and g.plays == projection.plays_after, "Resolution commits the projected round")
	g.enemy_hp = 1
	g.enemy_burn = 4
	g.hand.assign([Models.CardInstance.new("root_wall", 1)])
	g.selected.assign([0])
	projection = g.preview_round()
	expect(projection.applied_damage == 1 and projection.incoming == 0 and projection.phase == Ids.REWARD, "Projection accounts for burn kills and excludes overkill")
	g.play()
	expect(g.phase == Ids.REWARD and g.total_damage == 1, "Burn-kill projection agrees with committed reward transition")
	var snapshot: Dictionary = g.snapshot()
	snapshot.party[0].form_id = "missing"
	expect(g.party[0].form_id == "moss", "Serialized snapshots do not alias live individuals")
	var bad: Models.Individual = Rules.make_umbral("unknown", "vital", 8)
	expect(not Rules.evaluate([Models.CardInstance.new("fireball", 8)], [bad]).valid, "Malformed domain identities are rejected before catalog lookup")
	var trio: Array[Models.Individual] = [Rules.make_umbral("ember", "fierce", 1), Rules.make_umbral("moss", "vital", 2), Rules.make_umbral("volt", "swift", 3)]
	var effect: Models.CastEvaluation = Rules.evaluate([Models.CardInstance.new("fireball", 1), Models.CardInstance.new("root_wall", 2), Models.CardInstance.new("lightning", 3)], trio)
	effect.name = "Texto alterado"
	expect(Ids.TRIPLE_LINK in effect.events, "Feedback events remain stable when display copy changes")
	print(JSON.stringify({"suite": "domain_contracts", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)

func _copy_species() -> Array[Content.Species]:
	var entries: Array[Content.Species] = []
	for species in Content.DATABASE.species:
		entries.append(species.duplicate_deep(Resource.DEEP_DUPLICATE_ALL))
	return entries
