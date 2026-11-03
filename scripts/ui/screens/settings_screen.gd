extends "res://scripts/ui/screens/modal_view.gd"

func render_screen() -> void:
	var body: VBoxContainer = _modal_frame("Opções", "Ajuste o ritmo, a leitura e o som para você.", 820)
	for key in ["music", "sfx"]:
		var row: HBoxContainer = UI.row(18)
		body.add_child(row)
		row.add_child(ui.label("Música" if key == "music" else "Efeitos e interface", 24))
		var slider = HSlider.new()
		slider.custom_minimum_size = Vector2(330, 48)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = preferences.values[key]
		row.add_child(slider)
		navigation.register(slider, "settings." + key, Ids.SETTINGS)
		var percentage: Label = ui.label("%d%%" % int(slider.value * 100), 22, UI.tokens.gold)
		percentage.custom_minimum_size.x = 90
		row.add_child(percentage)
		slider.value_changed.connect(func(value: float): percentage.text = "%d%%" % int(value * 100); preferences.set_value(key, value))
	for key in ["reduced_motion", "flashes", "large_text"]:
		var check = CheckButton.new()
		check.text = {"reduced_motion": "Movimento reduzido", "flashes": "Flashes de impacto", "large_text": "Texto ampliado"}[key]
		check.custom_minimum_size.y = 56
		check.button_pressed = preferences.values[key]
		body.add_child(check)
		navigation.register(check, "settings." + key, Ids.SETTINGS)
		check.toggled.connect(func(value: bool): preferences.set_value(key, value))
	body.add_child(ui.paragraph("Movimento reduzido desativa tremores e partículas. Flashes começam desativados. Estas opções ficam salvas neste dispositivo.", 20))
	_button(body, "VOLTAR", request.bind("pop"), "settings.back", Ids.SETTINGS, true)
