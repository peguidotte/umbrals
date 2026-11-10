extends SceneTree
## Reuse exact existing runtime pixels; do not duplicate or redraw creature identities.
const Content = preload("res://scripts/content.gd")
const BattleArt = preload("res://scripts/ui/battle_art.gd")

func source(binding: String, lookup: Dictionary) -> Dictionary:
	var texture: Texture2D = BattleArt.texture(binding)
	var crop: Rect2 = Rect2(Vector2.ZERO, Vector2.ONE)
	if texture is AtlasTexture:
		var atlas: AtlasTexture = texture
		texture = atlas.atlas
		crop = Rect2(atlas.region.position / texture.get_size(), atlas.region.size / texture.get_size())
	var ref: Dictionary = lookup.get(texture.resource_path, {})
	if ref.is_empty():
		push_error("No exact asset role for portrait: " + texture.resource_path)
		return {}
	return {"asset": ref, "status": "prototype", "review": "Existing runtime identity reused; miniature framing awaits in-game review", "crop": [crop.position.x, crop.position.y, crop.size.x, crop.size.y], "focal_point": [crop.get_center().x, crop.get_center().y]}

func _init() -> void:
	var inventory: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/asset-manifest.json"))
	var lookup: Dictionary = {}
	for item: Dictionary in inventory.assets:
		if item.kind == "texture": lookup["res://" + str(item.path)] = {"id": item.module, "version": item.version, "role": item.role}
	var forms: Dictionary = {}
	var enemies: Dictionary = {}
	for species: String in Content.species_ids():
		for form: String in Content.form_ids(species):
			forms[form] = source(Content.art_binding({"species": species, "form_id": form}), lookup)
	for encounter: Dictionary in Content.ENCOUNTERS:
		for enemy: Dictionary in encounter.enemies: enemies[str(enemy.art)] = source(str(enemy.art), lookup)
	print(JSON.stringify({"target_portraits": forms, "enemy_portraits": enemies}))
	quit()
