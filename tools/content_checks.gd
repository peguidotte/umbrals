extends SceneTree
## Pure graph contracts plus actual package assets and membership. Drafts never enter play.
const Content = preload("res://scripts/content.gd")
const Catalog = preload("res://scripts/domain/catalog_validation.gd")
const Packages = preload("res://tools/package_validation.gd")

func _init() -> void:
	var errors: Array[String] = Catalog.validate(Content.DATABASE.species)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/asset-manifest.json"))
	var files: Dictionary = {}
	var forms: int = 0
	for species in Content.DATABASE.species:
		errors.append_array(Packages.validate(species, manifest))
		forms += species.forms.size()
		for path in Packages.assets(species): files[path] = true
	var indexed: Dictionary = {}
	for asset in manifest.assets: indexed["res://" + asset.path] = asset
	for encounter in Content.ENCOUNTERS:
		for path in [encounter.enemy.art_path, encounter.environment.background_path, "res://assets/%s.wav" % encounter.environment.music_id, "res://assets/%s.wav" % encounter.environment.boss_music_id]:
			files[path] = true
			if not FileAccess.file_exists(path) or not indexed.has(path): errors.append("Missing environment/enemy asset or provenance: " + path)
			elif FileAccess.get_sha256(path) != indexed[path].sha256: errors.append("Environment/enemy asset hash mismatch: " + path)
	var drafts: Array[String] = []
	for id in DirAccess.get_directories_at("res://content/umbrals"):
		if Content.SPECIES.has(id): continue
		var path: String = "res://content/umbrals/%s/species.tres" % id
		if ResourceLoader.exists(path):
			var species = load(path)
			if species.ready_for_play: errors.append("Ready species is absent from catalog: " + id)
			else: drafts.append(id)
	var report: Dictionary = {"suite": "content_packages", "species": Content.DATABASE.species.size(), "forms": forms, "assets_checked": files.size(), "drafts": drafts, "checks": files.size() + forms + Content.DATABASE.species.size(), "failed": errors.size(), "errors": errors}
	var output = FileAccess.open(output_path("content-report.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  "))
	print(JSON.stringify(report))
	quit(0 if errors.is_empty() else 1)

func output_path(name: String) -> String:
	var directory: String = OS.get_environment("UMBRAL_RESULTS_DIR")
	return ("res://test-results" if directory.is_empty() else directory).path_join(name)
