extends RefCounted
const Species = preload("res://scripts/catalog/species_definition.gd")

static func assets(species: Species) -> PackedStringArray:
	var result: PackedStringArray = []
	for shape in species.forms:
		if shape == null or shape.presentation == null: continue
		result.append("res://assets/%s.wav" % shape.presentation.sound_id)
		for facing in ["left", "right"]:
			var direction = shape.presentation.direction(facing)
			if direction == null: continue
			result.append(direction.portrait_path)
			for clip in direction.clips:
				if clip != null: result.append_array(clip.frames)
		for power in shape.powers:
			if power != null: result.append(power.art_path)
	return result

static func validate(species: Species, manifest: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var prefix: String = "res://content/umbrals/%s/" % species.species_id
	if species.resource_path != prefix + "species.tres": errors.append("Species ID must match package path")
	if species.trait_script == null or not species.trait_script.resource_path.begins_with(prefix + "mechanics/"):
		errors.append("Trait must live in its species package")
	for shape in species.forms:
		if shape == null: continue
		if shape.resource_path != prefix + "forms/%s/form.tres" % shape.form_id: errors.append("Form ID must match package path")
		if shape.presentation == null: continue
		for facing in ["left", "right"]:
			var direction = shape.presentation.direction(facing)
			if direction != null and not direction.portrait_path.begins_with(prefix): errors.append("Portrait must belong to species package")
		for power in shape.powers:
			if power != null and (power.identity == null or power.identity.resource_path != prefix + "powers/%s.tres" % power.power_id): errors.append("Power identity must live in species powers folder")
	var recorded: Dictionary = {}
	for item in manifest.assets: recorded["res://" + item.path] = item
	for path in assets(species):
		if not FileAccess.file_exists(path): errors.append("Missing content asset: " + path)
		elif not recorded.has(path): errors.append("Asset lacks provenance: " + path)
		elif FileAccess.get_sha256(path) != recorded[path].sha256: errors.append("Asset hash differs from provenance: " + path)
	var path: String = prefix + "provenance.json"
	if not FileAccess.file_exists(path): errors.append("Missing species provenance")
	else:
		var provenance: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not provenance is Dictionary or provenance.get("species_id") != species.species_id or not provenance.get("assets") is Array:
			errors.append("Malformed species provenance")
		else:
			var expected: Array = []
			for item in manifest.assets:
				if str(item.path).begins_with(prefix.trim_prefix("res://")): expected.append(item)
			if provenance.assets != expected: errors.append("Species provenance differs from global manifest")
	return errors
