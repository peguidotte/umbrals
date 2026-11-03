extends "res://scripts/ui/screens/modal_view.gd"

func render_screen() -> void:
	match screen:
		Ids.PAUSE:
			var body: VBoxContainer = _modal_frame("O bosque espera.", "Sua expedição está em pausa.", 650)
			_button(body, "CONTINUAR", request.bind("pop"), "pause.resume", screen, true)
			_button(body, "OPÇÕES", request.bind("push", Ids.SETTINGS), "pause.settings", screen)
			_button(body, "COMO JOGAR", request.bind("push", Ids.HELP), "pause.help", screen)
			_button(body, "VOLTAR AO TÍTULO", request.bind("push", Ids.CONFIRM_MENU), "pause.menu", screen)
		Ids.HELP:
			var body: VBoxContainer = _modal_frame("Seu time é o seu grimório.", "Leia a intenção do inimigo e escolha como responder.", 930)
			body.add_child(ui.paragraph("1. Selecione de 1 a 3 poderes. Cada rodada oferece 3 energia.\n2. Confira dano, escudo, cura e fôlego previsto antes de conjurar.\n3. Escudo absorve o revide e dura só esta rodada.\n4. Queimadura acumula, causa dano ao conjurar e perde 1 carga.\n5. Trait é da espécie; passiva é do indivíduo e permanece ao evoluir.\n6. Capture para mudar o grimório. Evolua para abrir um poder novo.\n7. São 7 rodadas e 2 trocas por encontro.", 23, UI.tokens.paper))
			body.add_child(ui.paragraph("1–6: poderes  ·  Enter: selecionar em foco  ·  Espaço: conjurar\nR: trocar  ·  C: inspecionar  ·  Esc: pausa/voltar\nControle: A seleciona, X conjura, RB troca, Y inspeciona e B volta.", 20, UI.tokens.gold))
			_button(body, "VOLTAR", request.bind("pop"), "help.back", screen, true)
		Ids.CREDITS:
			var body: VBoxContainer = _modal_frame("Feito para despertar ecos.", "", 850)
			body.add_child(ui.paragraph("Umbral: Ecos do Bosque\nCriaturas e poderes: arte vetorial original.\nCenário: criado com Image Gen para este projeto.\nÁudio: síntese original, sem samples externos.\nFontes: DejaVu Sans e DejaVu Serif.", 24, UI.tokens.paper))
			_button(body, "VOLTAR", request.bind("pop"), "credits.back", screen, true)
		Ids.VICTORY, Ids.DEFEAT: _ending()
		Ids.CONFIRM_MENU:
			var body: VBoxContainer = _modal_frame("Encerrar esta expedição?", "O progresso desta run será perdido. Suas estatísticas continuam salvas.", 760)
			_button(body, "CONTINUAR NO BOSQUE", request.bind("pop"), "confirm.cancel", screen, true)
			_button(body, "VOLTAR AO TÍTULO", request.bind("return_menu"), "confirm.yes", screen)

func _ending() -> void:
	var won: bool = game.phase == Ids.VICTORY
	var body: VBoxContainer = _modal_frame("A aurora tem seus nomes." if won else "Ainda existem outros ecos.", "Expedição concluída." if won else "Combine proteção, cura e queimadura para encontrar outro caminho.", 1050)
	body.add_child(UI.image(game.catalog.portrait_path(game.party[0]) if won else "res://assets/stag.svg", Vector2(240, 180)))
	body.add_child(ui.label("%d DANO  ·  %d UMBRALS  ·  SEMENTE %d" % [game.total_damage, game.party.size(), game.seed_value], 23, UI.tokens.gold, false, true))
	_button(body, "NOVA EXPEDIÇÃO", request.bind("new_seed"), "result.new", screen, true)
	_button(body, "REPETIR ESTA SEMENTE", request.bind("start_game", game.seed_value), "result.retry", screen)
	_button(body, "VOLTAR AO TÍTULO", request.bind("return_menu"), "result.menu", screen)
