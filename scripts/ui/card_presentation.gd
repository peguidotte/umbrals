extends RefCounted
## Pure view model. Callers supply existing gameplay values and filtered public targets.
## Neither card instances nor owner dictionaries acquire asset references.

static func build(card: Dictionary, owner: Dictionary, power: Dictionary, effect: Dictionary, owner_visual: Dictionary, target_visual: Dictionary) -> Dictionary:
	return {
		"instance_id": card.get("instance_id", -1),
		"owner_uid": owner.get("uid", -1),
		"owner_name": str(owner.get("name", "")),
		"species_id": str(owner.get("species", "")),
		"form_id": str(owner.get("form_id", "")),
		"power_id": str(card.get("power", "")),
		"power_name": str(power.get("name", "")),
		"power_nature": str(power.get("nature", "")),
		"cost": power.get("cost", 0),
		"effect": effect.duplicate(true),
		"visual": owner_visual.duplicate(true),
		"target": target_visual.duplicate(true),
		"placeholder_caption": ("ARTE EM REVISÃO" if owner_visual.get("art") != null else "ARTE PENDENTE") if owner_visual.get("placeholder", true) else "",
	}
