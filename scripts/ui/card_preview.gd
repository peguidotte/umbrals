extends RefCounted
## Read-only inspection/pile views reuse the hand's exact presentation component.
const PowerCard = preload("res://scripts/ui/power_card.gd")
const Catalog = preload("res://scripts/assets/card_visual_catalog.gd")

static func create(card: Dictionary, owner: Dictionary, team: Array, dimensions: Vector2, text_scale: float = 1.0) -> Control:
	if Catalog.active() == null: return null
	var preview: Button = PowerCard.new()
	preview.display_only = true
	preview.custom_minimum_size = dimensions
	preview.size = dimensions
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.focus_mode = Control.FOCUS_NONE
	preview.configure(card, owner, team, text_scale, true)
	preview.blocked = int(owner.get("hp", 0)) <= 0
	preview.blocked_caption = "INCAPACITADO"
	return preview
