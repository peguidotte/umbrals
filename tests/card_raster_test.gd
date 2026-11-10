extends SceneTree
## Verify real import pixels and mip levels, not only manifest dimensions.
const Catalog = preload("res://scripts/assets/card_visual_catalog.gd")
var checks: int = 0
var failed: int = 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func _init() -> void: call_deferred("run")

func run() -> void:
	var catalog = Catalog.open_release("ui/power-card-system", Catalog.PREVIEW_VERSION, true)
	for combination: Array in [["moss", "moss", "thorn_lash", "forest"], ["moss", "moss", "root_wall", "forest"], ["moss", "verdalio", "thorn_lash", "forest"], ["moss", "verdalio", "root_wall", "forest"], ["dew", "dew", "tidal_splash", "water"], ["dew", "dew", "dew_mend", "water"]]:
		var visual: Dictionary = catalog.resolve_owner_visual(combination[0], combination[1], combination[2], combination[3])
		var texture: Texture2D = visual.art
		expect(texture != null, "Candidate loads: " + str(combination))
		if texture == null: continue
		var path: String = Catalog.texture_source(texture)
		var source: Image = Image.load_from_file(path)
		var imported: Image = (load(path) as Texture2D).get_image()
		var prepared: Image = texture.get_image()
		expect(source.get_width() >= 1024 and source.get_height() >= 1024 and imported.get_size() == source.get_size() and prepared.get_size() == source.get_size(), "Source, import and prepared level zero retain the exact high resolution of each original: " + path)
		expect(prepared.has_mipmaps() and prepared.get_mipmap_count() >= 10, "Complete reduction pyramid survives actual texture upload: " + path)
		prepared.clear_mipmaps()
		imported.clear_mipmaps()
		for decoded: Image in [source, imported, prepared]: decoded.convert(Image.FORMAT_RGBA8)
		expect(source.get_data() == imported.get_data() and imported.get_data() == prepared.get_data(), "Lossless level zero matches actual original PNG pixels: " + path)
		expect(catalog.resolve_owner_visual(combination[0], combination[1], combination[2], combination[3]).art == texture, "Duplicate cards reuse the prepared pyramid: " + path)
	var memory: Dictionary = catalog.coverage_diagnostics()
	expect(memory.decoded_bytes_with_mipmaps > memory.estimated_rgba_bytes * .8 and memory.cached_textures <= memory.cache_limit, "Bounded cache reports actual mip data rather than compressed PNG sizes")
	for profile: Dictionary in memory.texture_profiles:
		expect(profile.mipmap_count > 0 and profile.width > 0 and profile.height > 0, "Every cached card component has measured reduction levels")
	print(JSON.stringify({"suite": "card_raster", "checks": checks, "failed": failed, "metrics": memory}))
	quit(0 if failed == 0 else 1)
