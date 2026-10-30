extends SceneTree
const Assets = preload("res://scripts/assets/catalog.gd")
const Paths = preload("res://scripts/assets/binding_paths.gd")
const Content = preload("res://scripts/content.gd")
var checks: int = 0
var failed: int = 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func _init() -> void:
	for binding: String in Paths.PATHS:
		expect(Assets.resource(binding) != null, "Pinned resource loads: " + binding)
	for species: Dictionary in Content.SPECIES.values():
		for art: String in species.art:
			expect(Assets.texture(art) != null, "Every species and evolution has a pinned portrait: " + art)
	for power: Dictionary in Content.POWERS.values():
		expect(Assets.texture(power.art) != null, "Every power has a pinned illustration: " + power.art)
	for enemy: Dictionary in Content.ENCOUNTERS:
		expect(Assets.texture(enemy.art) != null, "Every encounter has a pinned character: " + enemy.art)
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/catalog.json"))
	for asset_id: String in catalog.modules:
		for version: String in catalog.modules[asset_id].versions:
			var release: Dictionary = Assets.manifest(asset_id, version)
			for animation: String in release.get("animations", {}):
				var clip: Dictionary = release.animations[animation]
				for low: bool in [false, true]:
					var frames: SpriteFrames = Assets.sprite_frames(asset_id, version, animation, low)
					expect(frames != null and frames.get_frame_count(animation) == int(clip.frames), "Every frame imports: " + asset_id + ":" + animation)
					expect(is_equal_approx(frames.get_animation_speed(animation), float(clip.fps)), "Animation timing survives migration")
					var layout: Dictionary = Assets.sprite_layout(asset_id, version, animation, low)
					expect(layout.has("offset") and layout.scale.x > 0 and layout.scale.y > 0, "Pivot and logical size are available")
	var paged: SpriteFrames = Assets.sprite_frames("attacks/fireball-comet", "1.0.0", "impact")
	expect(paged.get_frame_count(&"impact") == 48, "Two-page comet has all 48 frames")
	var boundary: AtlasTexture = paged.get_frame_texture(&"impact", 36) as AtlasTexture
	expect(boundary.region == Rect2(0, 0, 640, 640), "Page two begins at its own top-left cell")
	var normal: Dictionary = Assets.sprite_layout("attacks/fireball-umbral-cast", "1.0.0", "projectile")
	var low_layout: Dictionary = Assets.sprite_layout("attacks/fireball-umbral-cast", "1.0.0", "projectile", true)
	expect((normal.offset * normal.scale).is_equal_approx(low_layout.offset * low_layout.scale), "Quality tiers preserve the world pivot")
	var copied: Dictionary = Assets.manifest("attacks/fireball-comet", "1.0.0")
	copied.description = "Caller mutation"
	expect(Assets.manifest("attacks/fireball-comet", "1.0.0").description != "Caller mutation", "Consumers cannot mutate the cached manifest")
	print(JSON.stringify({"suite":"asset_catalog", "checks":checks, "failed":failed}))
	quit(0 if failed == 0 else 1)
