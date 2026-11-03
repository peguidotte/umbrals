extends SceneTree

const Catalog = preload("res://scripts/catalog/gameplay_catalog.gd")
const Effects = preload("res://scripts/battle/item_effects/registry.gd")
const Manifest = preload("res://scripts/catalog/content_manifest.gd")
const Item = preload("res://scripts/catalog/item_resource.gd")

var checks: int = 0
var failed: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed += 1
		push_error(message)

func _initialize() -> void:
	var first = Catalog.new()
	check(first.items() == {"potion": {"name": "Poção", "cost": 1, "heal": 18}, "revive": {"name": "Reanimar", "cost": 1, "revive_ratio": 0.35}}, "legacy item projection preserved")
	var copy = first.powers()
	copy.fireball.conditions.fake = 1
	check(not first.powers().fireball.conditions.has("fake"), "power copy isolated")
	var item = Item.new()
	item.id = "herb"
	item.name = "Herb"
	item.cost = 1
	item.effect_id = "heal"
	item.effect_parameters = {"heal": 7}
	var fixture = Manifest.new()
	fixture.entries.append(item)
	var isolated = Catalog.new(Catalog.POWER_MANIFEST, fixture, Catalog.ENCOUNTER_MANIFEST)
	item.effect_parameters.heal = 99
	check(isolated.items().herb.heal == 7, "resource snapshot isolated")
	check(not first.items().has("herb"), "fixture isolated")
	var outcome = Effects.resolve(isolated.item_effect("herb"), {"hp": 5, "max_hp": 20}, isolated.items().herb)
	check(outcome.valid and outcome.new_hp == 12, "custom item effect")
	check(not Effects.resolve("unknown", {"hp": 5, "max_hp": 20}, {}).valid, "unknown effect rejected")
	check(Effects.resolve("heal", {"hp": 20, "max_hp": 20}, {"heal": 7}).amount == 0, "full health resolution")
	var experimental = Item.new()
	experimental.id = "experimental"
	experimental.effect_id = "unknown"
	experimental.effect_parameters = {"custom_amount": 12}
	var custom_manifest = Manifest.new()
	custom_manifest.entries.append(experimental)
	var custom = Catalog.new(Catalog.POWER_MANIFEST, custom_manifest, Catalog.ENCOUNTER_MANIFEST)
	check(custom.items().experimental.custom_amount == 12, "generic parameters projected")
	check(not Effects.resolve(custom.item_effect("experimental"), {"hp": 5, "max_hp": 20}, custom.items().experimental).valid, "unregistered behavior fails closed")
	print(JSON.stringify({"suite": "content_resources", "checks": checks, "failed": failed}))
	quit(1 if failed else 0)
