extends RefCounted
## Help content emits navigation intents; the screen stack owns transitions.
signal control_created(control: Control, key: String)
signal navigation_requested(destination: String)
const UI = preload("res://scripts/ui/kit.gd")
const TitleButton = preload("res://scripts/ui/title_button.gd")

func build(frame: VBoxContainer, ui: RefCounted, size: Vector2, menu: bool, reduced_motion: bool) -> void:
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(460, size.y - 320)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode = Control.FOCUS_ALL
	frame.add_child(scroll)
	var body: VBoxContainer = UI.column(16)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	body.add_child(ui.label("Na sala de repouso", 25, UI.GOLD))
	body.add_child(ui.paragraph("A/D, setas ou analógico movem o personagem; E/Enter/A consulta o objeto próximo. Mouse e toque indicam um ponto no chão para caminhar. Tocar no livro ou na bancada aproxima o personagem antes de consultar; atravessar a saída à direita abre a preparação. Tab percorre os objetos; Esc/B ou o discreto botão no canto retornam ao título. A bancada de melhorias ainda está indisponível.", 22))
	body.add_child(ui.label("Escolha o caminho do bosque", 25, UI.GOLD))
	body.add_child(ui.paragraph("Na expedição, selecione um ponto do mapa para ver o que ele oferece e confirme para seguir. Após a primeira clareira, a mata oferece combate e recompensa; a nascente recupera até 25% do HP máximo dos aliados vivos, sem reanimar ou dar uma recompensa. Sua escolha fecha a outra rota.\nCONTINUAR EXPEDIÇÃO retoma o último estado confirmado, inclusive o turno de combate. Comandos ainda não conjurados são desfeitos; cartas e sorteios ficam preservados. O treino de batalha é separado da expedição salva.", 22))
	body.add_child(ui.paragraph("1. Selecione poderes da mão. Veja ações livres e comandos no campo.\n2. Escolha os alvos clicando nas criaturas. As vagas são superior, central e inferior; não há retaguarda.\n3. Abra PLANO para alterar alvos, retirar comandos ou tocar em i e consultar um poder.\n4. Conjure quando estiver pronto. Prioridade e velocidade intercalam aliados e inimigos; clicar primeiro não antecipa o golpe.", 23, UI.PAPER))
	body.add_child(ui.label("Entenda o resultado", 25, UI.GOLD))
	body.add_child(ui.paragraph("RESUMO mostra a última rodada: HP perdido, escudo absorvido, resistências, efeitos e reações. Escudo protege nesta rodada; Queima atinge o HP mesmo com escudo. Informação parcial mostra a categoria inimiga, sem prometer dano ou alvo.", 22))
	body.add_child(ui.paragraph("Encharcado + Raio: Condução dobra a potência.\nSemeado + Bosque: Brotação dá escudo à fonte.\nSemeado + Água: Floração cura a fonte.\nSemeado + Fogo: Incêndio aplica Queima.\nUma semente ativa uma reação e é consumida. Interferência enfraquece o próximo ataque, sem impedir ações.", 22, UI.LEAF))
	body.add_child(ui.label("Time e recursos", 25, UI.GOLD))
	body.add_child(ui.paragraph("Comece com 1; até 3 no campo e 6 no time. Capture para uma vaga livre ou para a reserva, por escolha. Cartas de reservas aptos ficam fora do baralho; a entrada custa 1 ação e mistura suas cartas na próxima compra normal. O substituto recebe o golpe da vaga.\nNa mochila, você começa com 2 poções e 1 reanimação. Usar custa 1 ação; consultar é grátis. Reanimar devolve HP agora; se estiver em campo, age na próxima rodada. Reposição após nocaute é gratuita ao terminar a fila; cartas do incapacitado continuam bloqueadas.\nRESORTEAR passa a rodada inteira: nenhum comando aliado executa, os inimigos agem e a mão se renova.", 22))
	body.add_child(ui.paragraph("1–6: poderes · Espaço: conjurar · Q/E: alvo · P: plano\nBackspace: limpar · C: inspecionar · Esc: voltar\nControle: A seleciona, X conjura, RB resorteia, Y inspeciona, LB abre o plano e B volta.", 19, UI.GOLD))
	var credits: Button = _button(ui, "CRÉDITOS", menu, reduced_motion, false)
	frame.add_child(credits)
	control_created.emit(credits, "help.credits")
	credits.pressed.connect(func(): navigation_requested.emit("credits"))
	var back: Button = _button(ui, "VOLTAR", menu, reduced_motion, true)
	frame.add_child(back)
	control_created.emit(back, "help.back")
	back.pressed.connect(func(): navigation_requested.emit("back"))
	control_created.emit(scroll, "help.content")

func _button(ui: RefCounted, text: String, menu: bool, reduced_motion: bool, primary: bool) -> Button:
	if menu:
		var button = TitleButton.new()
		button.text = text
		button.primary = primary
		button.reduced_motion = reduced_motion
		button.custom_minimum_size.y = 56
		return button
	return ui.button(text, func(): pass, "", primary)
