extends Control
## Enlarged read-only projection of the aimed hand card. No extra input surface,
## card instance, Rules query or world texture/filter change.
const Renderer = preload("res://scripts/ui/card_renderer.gd")
var model: Dictionary = {}
var portrait: Texture2D
var state: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	hide()

func show_card(card: Button) -> void:
	if card == null or card.presentation.is_empty():
		hide()
		return
	model = card.presentation
	portrait = card.owner_texture
	state = {"chosen": true, "focused": false, "aiming": card.aiming, "blocked": card.blocked, "blocked_caption": card.blocked_caption, "insufficient_actions": card.insufficient_actions, "text_scale": card.text_scale}
	show()
	queue_redraw()

func _draw() -> void:
	if not model.is_empty(): Renderer.draw(self, model, portrait, state)
