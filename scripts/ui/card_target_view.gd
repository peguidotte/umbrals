extends RefCounted
## Current public bodies only. No enemy plan, forecast or future occupant is read.
const Content = preload("res://scripts/content.gd")

static func project(card: Dictionary, power: Dictionary, owner: Dictionary, party: Array, enemies: Array, selected: bool) -> Dictionary:
	if not selected: return {"kind": "none", "label": ""}
	var scope: String = str(power.get("scope", "single"))
	if scope != "single":
		return {"kind": "area", "label": {"upper_pair": "Superior + centro", "lower_pair": "Centro + inferior", "all": "Todos os alvos"}.get(scope, "Área"), "scope": scope}
	var side: String = str(power.get("target", "enemy"))
	if side == "self": return _body(owner, false)
	var slot: int = int(card.get("target_slot", 1))
	for body: Dictionary in party if side == "ally" else enemies:
		if int(body.get("slot", -1)) == slot: return _body(body, side != "ally")
	return {"kind": "empty", "label": "Vaga vazia", "slot": slot}

static func _body(body: Dictionary, enemy: bool) -> Dictionary:
	var form: String = Content.form_id(body)
	var name: String = str(body.get("name", "")) if enemy else Content.display_name(body)
	if name.is_empty(): name = Content.display_name(body)
	var enemy_art: bool = enemy and not str(body.get("art", "")).is_empty()
	return {"kind": "single", "enemy": enemy, "portrait_source": "enemy_art" if enemy_art else "form", "portrait_key": str(body.art) if enemy_art else form, "uid": int(body.uid), "label": "%s · %d" % [name, int(body.uid)]}
