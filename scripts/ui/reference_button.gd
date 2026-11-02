extends Button
## Artwork plate on a real semantic Button. Hit/focus bounds follow the artwork.
var plate: Texture2D
var selected: bool = false
var text_zoom: float = 1.0
var caption_font: Font = preload("res://assets/fonts/cormorant/versions/1.0.0/display.ttf")
func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]: add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]: add_theme_color_override(state, Color.TRANSPARENT)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
func _draw() -> void:
	if plate != null: draw_texture_rect(plate, Rect2(Vector2.ZERO, size), false, Color(0.72,0.72,0.72) if disabled else Color.WHITE)
	if text_zoom > 1.0 and not text.is_empty():
		var area = Rect2(size.x*0.22,size.y*0.08,size.x*0.70,size.y*0.69)
		draw_rect(area,Color(0.025,0.055,0.06,0.97))
		var font_size: int = int(minf(30.0,size.y*0.42)*text_zoom)
		while font_size > 16 and caption_font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x > area.size.x-6: font_size -= 1
		var extent: Vector2 = caption_font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
		draw_string(caption_font,Vector2(area.get_center().x-extent.x*0.5,area.get_center().y+font_size*0.3),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("f3e6c5"))
	if (has_focus() or is_hovered()) and not disabled and not selected:
		draw_rect(Rect2(Vector2(2,2), size-Vector2(4,4)), Color(0.92,0.78,0.47,0.85), false, 1.0)
