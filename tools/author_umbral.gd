extends SceneTree
const Species = preload("res://scripts/catalog/species_definition.gd")
const Form = preload("res://scripts/catalog/form_definition.gd")
const Power = preload("res://scripts/catalog/power_definition.gd")
const Evolution = preload("res://scripts/catalog/evolution_definition.gd")
const Presentation = preload("res://scripts/catalog/presentation_definition.gd")
const Direction = preload("res://scripts/catalog/direction_definition.gd")
const Clip = preload("res://scripts/catalog/clip_definition.gd")
const Catalog = preload("res://scripts/domain/catalog_validation.gd")
const Packages = preload("res://tools/package_validation.gd")
const Content = preload("res://scripts/content.gd")

func argument(key: String, fallback: String = "") -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = args.find(key)
	return args[index + 1] if index >= 0 and index + 1 < args.size() else fallback

func save(resource: Resource, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	assert(ResourceSaver.save(resource, path) == OK)
	resource.take_over_path(path)

func _init() -> void:
	var id: String = argument("--id")
	if not Catalog.valid_id(id):
		printerr("Invalid species ID")
		quit(2)
		return
	if argument("--operation") == "register":
		_register(id)
		return
	var folder: String = "res://content/umbrals/" + id
	if DirAccess.dir_exists_absolute(folder):
		printerr("Refusing to overwrite existing package")
		quit(2)
		return
	var ids: PackedStringArray = argument("--forms").split(",", false)
	var seen: Dictionary = {}
	for form_id in ids:
		if not Catalog.valid_id(form_id) or seen.has(form_id):
			printerr("Invalid/duplicate form ID")
			quit(2)
			return
		seen[form_id] = true
	if ids.is_empty():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder + "/mechanics"))
	var source = FileAccess.open(folder + "/mechanics/trait.gd", FileAccess.WRITE)
	source.store_string("extends \"res://scripts/domain/trait_behavior.gd\"\n## TODO: implement pure apply() and is_implemented(); add numerical expected-value tests.\n")
	source.close()
	var species = Species.new()
	species.species_id = id
	species.description = "TODO: descrição da espécie"
	species.initial_form_id = ids[0]
	species.passive_pool = PackedStringArray(["fierce"])
	species.trait_id = id + "_trait"
	species.trait_name = "TODO: trait"
	species.trait_description = "TODO: efeito de intensidade %d"
	species.trait_script = load(folder + "/mechanics/trait.gd")
	var identity = Power.Identity.new()
	identity.power_id = id + "_core"
	identity.name = "TODO: poder"
	identity.description = "TODO: descrição do poder"
	identity.art_path = folder + "/powers/core.png"
	save(identity, folder + "/powers/" + identity.power_id + ".tres")
	for index in range(ids.size()):
		var form = Form.new()
		form.form_id = ids[index]
		form.display_name = argument("--name", id) if index == 0 else ids[index]
		form.description = "TODO: descrição da forma"
		var path: String = folder + "/forms/" + form.form_id
		var visual = Presentation.new()
		visual.authoring_notes = "DRAFT: forneça arte original/proveniência e revise cada direção/ação. Poses procedurais são declaradas explicitamente."
		for facing in ["left", "right"]:
			var direction = Direction.new()
			direction.portrait_path = path + "/portrait_%s.png" % facing
			direction.anchors.assign({"mouth": Vector2(0.5, 0.5), "attack_origin": Vector2(0.7, 0.5), "impact_target": Vector2(0.5, 0.5), "center": Vector2(0.5, 0.5)})
			for action in Clip.ACTIONS:
				var clip = Clip.new()
				clip.action_id = action
				clip.loop = action in ["idle", "move"]
				if action == "idle": clip.pose_offset = Vector2(0, 3); clip.duration = 4.5
				if action == "attack_ranged": clip.release_point = "mouth"; clip.release_time = 0.1
				direction.clips.append(clip)
			save(direction, path + "/animations/%s.tres" % facing)
			visual.set(facing, direction)
		save(visual, path + "/presentation.tres")
		form.presentation = visual
		var power = Power.new()
		power.identity = identity
		power.damage = 1
		save(power, path + "/powers/" + power.power_id + ".tres")
		form.powers.append(power)
		if index + 1 < ids.size():
			var transition = Evolution.new()
			transition.transition_id = "to_" + ids[index + 1]
			transition.target_form_id = ids[index + 1]
			form.evolutions.append(transition)
		save(form, path + "/form.tres")
		species.forms.append(form)
	save(species, folder + "/species.tres")
	var provenance = FileAccess.open(folder + "/provenance.json", FileAccess.WRITE)
	provenance.store_string(JSON.stringify({"species_id": id, "assets": []}, "  "))
	print(JSON.stringify({"draft": id, "forms": ids, "ready_for_play": false, "registered": false}))
	quit()

func _register(id: String) -> void:
	if Content.SPECIES.has(id):
		printerr("Species is already registered; existing catalog order is preserved")
		quit(2)
		return
	var path: String = "res://content/umbrals/%s/species.tres" % id
	if not ResourceLoader.exists(path):
		printerr("Package does not exist")
		quit(2)
		return
	var species: Species = load(path)
	species.ready_for_play = true
	var entries: Array[Species] = Content.DATABASE.species.duplicate()
	entries.append(species)
	var errors: Array[String] = Catalog.validate(entries)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/asset-manifest.json"))
	errors.append_array(Packages.validate(species, manifest))
	if not errors.is_empty():
		printerr(JSON.stringify({"registered": false, "errors": errors}))
		quit(1)
		return
	save(species, path)
	Content.DATABASE.species.append(species)
	save(Content.DATABASE, "res://content/catalog.tres")
	print(JSON.stringify({"registered": id, "position": Content.DATABASE.species.size() - 1}))
	quit()
