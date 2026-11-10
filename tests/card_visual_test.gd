extends SceneTree
const Catalog = preload("res://scripts/assets/card_visual_catalog.gd")
const Presentation = preload("res://scripts/ui/card_presentation.gd")
const Content = preload("res://scripts/content.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
const Expedition = preload("res://scripts/expedition/expedition.gd")
var checks: int = 0
var failed: int = 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func entry(binding: String) -> Dictionary:
	var lock: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/runtime-lock.json"))
	var ref: Dictionary = lock.bindings[binding].duplicate(true)
	ref.role = ref.file
	ref.erase("file")
	return {"asset": ref, "status": "prototype", "review": "Isolated resolver fixture using an existing icon; not new art"}

func fixture_catalog() -> RefCounted:
	var resolver = Catalog.new()
	resolver._production = false
	for binding: String in ["attacks/lightning", "attacks/rain", "umbrals/volt", "umbrals/tempestral"]:
		var ref: Dictionary = entry(binding).asset
		resolver._allowed.append({"id": ref.id, "version": ref.version})
	resolver._data = {
		"families": {"volt": {"default_frame": entry("umbrals/volt"), "reuse_default_for_forms": ["volt"], "form_overrides": {"tempestral": entry("umbrals/tempestral")}}},
		"illustrations": {"volt": {"volt": {"lightning": entry("attacks/lightning")}, "tempestral": {"lightning": entry("attacks/rain")}}},
		"power_styles": {"water": {"tokens": {}, "art_border": entry("attacks/rain"), "title_plate": entry("attacks/rain"), "owner_plate": entry("attacks/rain")}},
		"target_portraits": {"tempestral": {"asset": entry("umbrals/tempestral").asset, "status": "prototype", "review": "fixture", "crop": [0.1, 0.1, 0.8, 0.8], "focal_point": [0.5, 0.5]}},
		"enemy_portraits": {"characters/spore": {"asset": entry("umbrals/volt").asset, "status": "prototype", "review": "fixture", "crop": [0, 0, 1, 1], "focal_point": [0.5, 0.5]}}
	}
	return resolver

func _init() -> void:
	call_deferred("run")

func run() -> void:
	expect(Catalog.from_binding() == null, "Unpromoted system never silently changes production presentation")
	var draft = Catalog.open_release("ui/power-card-system", "0.1.0", true)
	var absent: Dictionary = draft.resolve_owner_visual("dew", "dew", "rain", "water")
	expect(absent.placeholder and absent.art == null and absent.missing_entries.size() >= 5, "Draft exposes explicit pending art and components")
	var count: int = draft.coverage_diagnostics().missing_entries.size()
	draft.resolve_owner_visual("dew", "dew", "rain", "water")
	expect(draft.coverage_diagnostics().missing_entries.size() == count, "Missing key diagnostics are emitted once")
	var resolver = fixture_catalog()
	var baby: Dictionary = resolver.resolve_owner_visual("volt", "volt", "lightning", "water")
	var adult: Dictionary = resolver.resolve_owner_visual("volt", "tempestral", "lightning", "water")
	expect(baby.art != null and adult.art != null and baby.art != adult.art, "Form selects distinct exact illustrations")
	expect(baby.frame != adult.frame, "Explicit form override wins over family default")
	expect(baby.style.title_plate == adult.style.title_plate and adult.style.title_plate == adult.art, "Power nature selects border and both plates independently of family")
	expect(resolver.resolve_owner_visual("volt", "volt", "lightning", "water").art == baby.art, "Copies share texture by exact reference")
	var wrong: Dictionary = resolver.resolve_owner_visual("volt", "unknown", "lightning", "water")
	expect(wrong.art == null and wrong.frame == null and wrong.placeholder, "Unknown form never inherits a baby or another family")
	var target: Dictionary = resolver.resolve_target_visual({"kind": "single", "portrait_key": "tempestral", "uid": 2, "label": "Niscor · 2", "private_plan": {"damage": 999}})
	expect(target.texture != null and target.uid == 2 and target.crop == [0.1, 0.1, 0.8, 0.8], "Target has its own reusable portrait and normalized crop")
	expect(not target.has("private_plan"), "Target adapter only copies allowed public fields")
	for kind: String in ["none", "empty", "area"]:
		expect(resolver.resolve_target_visual({"kind": kind, "portrait_key": "tempestral"}).texture == null, "No invented single recipient for " + kind)
	var replacement: Dictionary = resolver.resolve_target_visual({"kind": "single", "portrait_key": "characters/spore", "enemy": true, "uid": 1001, "label": "Esporo"})
	expect(replacement.texture != target.texture and replacement.uid == 1001, "Enemy portraits cannot alias a species form; slot occupant can change")
	var run_state = Expedition.new()
	run_state.new_run(42013)
	var before: Dictionary = run_state.snapshot()
	var owner: Dictionary = {"uid": 7, "species": "volt", "form_id": "volt", "name": "Nisca"}
	var card: Dictionary = {"instance_id": 81, "owner": 7, "power": "lightning"}
	var power: Dictionary = {"name": "Teste", "nature": "water", "cost": 2}
	var model: Dictionary = Presentation.build(card, owner, power, {"damage": 3}, baby, target)
	owner.form_id = "tempestral"
	var evolved: Dictionary = Presentation.build(card, owner, power, {"damage": 8}, adult, replacement)
	expect(model.instance_id == evolved.instance_id and model.owner_uid == evolved.owner_uid and model.visual.art != evolved.visual.art, "Visual evolution preserves card/individual identities and changes artwork")
	expect(model.cost == 2 and model.effect.damage == 3 and evolved.effect.damage == 8, "Stats come from caller data; artwork never defines effects/cost")
	model.effect.damage = 900
	model.visual.style.tokens["fixture"] = true
	expect(not baby.style.tokens.has("fixture") and not card.has("visual"), "View models do not mutate shared visuals or canonical cards")
	expect(run_state.snapshot() == before, "Presentation never changes snapshot, plan, decks or RNG")
	var missing: Dictionary = Presentation.build(card, owner, power, {}, absent, {"kind": "none"})
	expect(missing.placeholder_caption == "ARTE PENDENTE", "Development placeholder is explicitly marked")
	resolver.prewarm([{"species_id": "volt", "form_id": "volt", "power_id": "lightning", "nature": "water"}])
	expect(resolver.coverage_diagnostics().cached_textures <= Catalog.CACHE_LIMIT, "Visible-key prewarm respects bounded texture cache")
	resolver._cache_limit = 2
	resolver.resolve_owner_visual("volt", "tempestral", "lightning", "water")
	expect(resolver.coverage_diagnostics().cached_textures == 2, "LRU actually evicts texture references above its configured limit")
	expect(resolver.coverage_diagnostics().estimated_rgba_bytes > 0, "Diagnostics expose decoded RGBA estimate, not compressed download size")
	resolver._data.illustrations.volt.volt.lightning.asset.version = "99.0.0"
	expect(resolver.resolve_owner_visual("volt", "volt", "lightning", "water").art == null, "Unpinned reference does not resolve a cached texture or latest version")
	var unknown = Catalog.open_release("ui/no-such-presentation", "1.0.0", true)
	expect(unknown.coverage_diagnostics().missing_entries[0].reason == "unknown_release", "Unknown release fails safely without an asset lookup error")
	var production = fixture_catalog()
	production._production = true
	expect(production.resolve_owner_visual("volt", "volt", "lightning", "water").art == null, "Runtime production defense refuses prototype entries")
	print(JSON.stringify({"suite": "card_visuals", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)
