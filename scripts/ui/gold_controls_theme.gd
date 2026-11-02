extends RefCounted
## Shared styling for native gold buttons, switches, sliders and scrollbars.
const Gold = preload("res://scripts/ui/gold_theme.gd")
const UI = preload("res://scripts/ui/kit.gd")

static func make(text_scale: float = 1.0) -> Theme:
	var result = Theme.new()
	result.default_font = UI.BODY
	result.default_font_size = int(22*text_scale)
	for type in ["Button","CheckButton"]:
		for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			var box: StyleBoxFlat = Gold.box(state in ["pressed","hover_pressed","focus"],12)
			if type == "CheckButton":
				box.bg_color = Color.TRANSPARENT
				box.set_border_width_all(0)
				box.shadow_size = 0
				box.set_content_margin_all(0)
				if state == "focus": box.set_border_width_all(1)
			result.set_stylebox(state,type,box)
		for color in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
			result.set_color(color,type,Gold.PAPER)
	result.set_icon("checked","CheckButton",_svg('<rect x="1" y="3" width="62" height="26" rx="13" fill="#dec88d" stroke="#f3e6c5"/><circle cx="49" cy="16" r="9" fill="#101c23"/><path d="m45 16 3 3 5-6" fill="none" stroke="#f3e6c5" stroke-width="2"/>',64,32))
	result.set_icon("unchecked","CheckButton",_svg('<rect x="1" y="3" width="62" height="26" rx="13" fill="#14282a" stroke="#85917c"/><circle cx="15" cy="16" r="9" fill="#bac6b6"/>',64,32))
	for state in ["slider","grabber_area","grabber_area_highlight"]:
		var track = StyleBoxFlat.new()
		track.bg_color = Color("2d4541") if state == "slider" else Gold.GOLD
		track.set_corner_radius_all(3)
		track.content_margin_top = 3
		track.content_margin_bottom = 3
		result.set_stylebox(state,"HSlider",track)
	result.set_icon("grabber","HSlider",_svg('<path d="m12 2 9 12-9 12-9-12Z" fill="#dec88d" stroke="#f3e6c5" stroke-width="1.5"/>',24,28))
	result.set_icon("grabber_highlight","HSlider",_svg('<path d="m12 1 10 13-10 13L2 14Z" fill="#f3e6c5" stroke="#dec88d" stroke-width="2"/>',24,28))
	var focus: StyleBoxFlat = Gold.box(true,0)
	focus.bg_color = Color.TRANSPARENT
	result.set_stylebox("focus","HSlider",focus)
	for type in ["VScrollBar","HScrollBar"]:
		var track = StyleBoxFlat.new()
		track.bg_color = Color("102023")
		track.content_margin_left = 3
		result.set_stylebox("scroll",type,track)
		for state in ["grabber","grabber_highlight","grabber_pressed"]:
			var thumb = StyleBoxFlat.new()
			thumb.bg_color = Color("8d805a")
			thumb.set_corner_radius_all(3)
			result.set_stylebox(state,type,thumb)
	return result

static func _svg(shapes: String, width: int, height: int) -> Texture2D:
	var picture = Image.new()
	picture.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">%s</svg>'%[width,height,width,height,shapes])
	return ImageTexture.create_from_image(picture)
