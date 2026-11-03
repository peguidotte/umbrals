extends Control
## Displays one discovered record; navigation and history stay in codex.gd.
const Items = preload("res://scripts/ui/item_presentation.gd")
const Content = preload("res://scripts/content.gd")
const Gold = preload("res://scripts/ui/gold_theme.gd")
const Art = preload("res://scripts/ui/battle_art.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
const RefArt = preload("res://scripts/ui/reference_art.gd")
const Plate = preload("res://scripts/ui/reference_button.gd")
signal section_requested(section: String)
signal power_requested(id: String)
signal form_requested(id: String)
var progress: RefCounted
var register: Callable
var text_scale: float = 1.0
var category: String
var record_section: String

func setup(knowledge: RefCounted, registry: Callable, scale_value: float) -> void:
	progress = knowledge
	register = registry
	text_scale = scale_value
	custom_minimum_size = Vector2(742,870)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _label(parent: Control, text: String, rect: Rect2, font_size: int, color: Color = Gold.PAPER, display: bool = true) -> Label:
	var result: Label = Gold.label(text,int(font_size * text_scale),color,display)
	RefArt.native(parent,result,rect)
	return result

func render(entry: Dictionary, kind: String, section: String) -> void:
	category = kind
	record_section = section
	for child in get_children():
		remove_child(child)
		child.queue_free()
	custom_minimum_size.y = 870
	var known: bool = progress.knows(category,entry.id)
	if known and category == "umbrals" and entry.id == "ember":
		RefArt.patch(self,"ui/gold-codex-art",Rect2(910,0,762,435),Rect2(0,0,762,435))
	else:
		var hero: TextureRect = RefArt.image(self,Art.texture(entry.art) if category == "umbrals" else Assets.texture(entry.art),Rect2(45,80,665,340) if category == "umbrals" else Rect2(210,150,340,210))
		hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hero.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if category == "umbrals" else CanvasItem.TEXTURE_FILTER_LINEAR
		if not known: hero.modulate = Color(0.02,0.035,0.04)
	var title: Label = _label(self,str(entry.name).to_upper() if known else "???",Rect2(35,438,460,62),48)
	if known and category == "umbrals" and entry.id == "ember" and text_scale <= 1.0:
		title.modulate.a = 0
		RefArt.patch(self,"ui/gold-codex-art",Rect2(928,438,233,61),Rect2(18,438,233,61))
	# Replace the former evolution column with one calm, full-width reading area.
	var reading = ColorRect.new()
	reading.color = Color("09191d")
	reading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefArt.native(self,reading,Rect2(16,544,728,1800))
	if not known:
		var unknown: Label = _label(self,"Ainda não descoberto.\nExplore o bosque para revelar este registro.",Rect2(35,600,650,120),25,Gold.MUTED)
		unknown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		return
	RefArt.patch(self,"ui/gold-codex-art",Rect2(1435,457,220,55),Rect2(525,457,220,55))
	if category == "umbrals" and not str(entry.species).is_empty(): _form_selector(entry)
	_record_tabs()
	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation",14)
	RefArt.native(self,body,Rect2(35,621,680,200))
	body.minimum_size_changed.connect(_fit_body.bind(body))
	if record_section == "story": _description(body,entry)
	else: _effects(body,entry)
	_fit_body.call_deferred(body)

func _form_selector(entry: Dictionary) -> void:
	var species: Dictionary = Content.SPECIES[entry.species]
	_label(self,Content.nature_text({"species":entry.species,"form_id":entry.form_id}),Rect2(35,496,300,38),24,Color(species.color))
	var alternatives: Array = []
	for form_id in Content.form_ids(entry.species):
		if form_id != entry.form_id and progress.knows("umbrals", form_id):
			alternatives.append({"id": form_id, "name": Content.display_name({"species": entry.species, "form_id": form_id})})
	_form_links(alternatives)

## DTOs contain only the ID and display name of each discovered alternative.
func _form_links(alternatives: Array) -> void:
	if alternatives.is_empty():
		_label(self,"Outras formas ainda não descobertas",Rect2(335,517,385,28),17,Gold.MUTED)
		return
	var row: HBoxContainer
	if alternatives.size() > 1:
		var scroll = ScrollContainer.new()
		scroll.name = "FormLinksScroll"
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.follow_focus = true
		RefArt.native(self,scroll,Rect2(350,512,370,42))
		row = HBoxContainer.new()
		row.add_theme_constant_override("separation",12)
		scroll.add_child(row)
	for index in range(alternatives.size()):
		var alternative: Dictionary = alternatives[index]
		var form = Button.new()
		form.text = "Ver " + str(alternative.name)
		form.accessibility_name = form.text
		form.tooltip_text = "Consultar outra forma já descoberta"
		form.add_theme_font_override("font",Gold.display_font())
		form.add_theme_font_size_override("font_size",int(21*text_scale))
		form.add_theme_color_override("font_color",Gold.GOLD)
		form.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
		if row == null:
			RefArt.native(self,form,Rect2(350,512,370,32))
		else:
			form.custom_minimum_size = Vector2(180,32)
			row.add_child(form)
		register.call(form,"codex.evolution" if index == 0 else "codex.evolution.%d" % index,"codex")
		form.pressed.connect(form_requested.emit.bind(str(alternative.id)))

func _record_tabs() -> void:
	var names: Array = ["História","Poderes e traços"] if category == "umbrals" else ["Descrição","Efeito"]
	for i in range(2):
		var section: String = "story" if i == 0 else "details"
		var tab = Button.new()
		tab.text = names[i]
		tab.accessibility_name = names[i]
		tab.add_theme_font_override("font",Gold.display_font())
		tab.add_theme_font_size_override("font_size",int(25*text_scale))
		var active: bool = section == record_section
		tab.add_theme_color_override("font_color",Gold.PAPER if active else Gold.MUTED)
		for state in ["normal","hover","pressed","focus"]:
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.07,0.13,0.13,0.8) if active else Color.TRANSPARENT
			style.border_color = Gold.GOLD if active or state != "normal" else Color("4b594c")
			style.border_width_bottom = 2 if active else 1
			tab.add_theme_stylebox_override(state,style)
		RefArt.native(self,tab,Rect2(35+i*340,558,330,44))
		register.call(tab,"codex.section."+section,"codex")
		tab.pressed.connect(section_requested.emit.bind(section))

func _fit_body(body: VBoxContainer) -> void:
	if not is_instance_valid(body) or body.get_parent() != self: return
	body.size.y = body.get_combined_minimum_size().y
	custom_minimum_size.y = maxf(870,body.position.y+body.size.y+24)

func _heading(body: VBoxContainer, text: String) -> void:
	body.add_child(Gold.label(text,int(29*text_scale),Gold.GOLD,true))

func _paragraph(body: VBoxContainer, text: String, muted: bool = false) -> void:
	var paragraph: Label = Gold.paragraph(text,int(22*text_scale),Gold.MUTED if muted else Gold.PAPER)
	paragraph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(paragraph)

func _description(body: VBoxContainer, entry: Dictionary) -> void:
	match category:
		"umbrals":
			var memory: Dictionary = Content.UMBRAL_LORE.get(entry.id,{"title":"Um eco do bosque","text":"Umbral encontrado durante suas expedições pelo bosque."})
			_heading(body,str(memory.title))
			_paragraph(body,str(memory.text))
		"items":
			_heading(body,str(entry.name))
			_paragraph(body,str(Content.ITEM_DESCRIPTIONS.get(entry.id,"Item guardado na mochila.")))
		"powers":
			_heading(body,str(entry.name))
			_paragraph(body,str(Content.POWER_DESCRIPTIONS.get(entry.id,"Uma técnica registrada durante suas expedições.")))
		"passives":
			_heading(body,str(entry.name))
			_paragraph(body,Content.PASSIVES[entry.id].description)
			_paragraph(body,"Este instinto pertence ao indivíduo e permanece com ele ao evoluir.",true)

func _effects(body: VBoxContainer, entry: Dictionary) -> void:
	match category:
		"umbrals": _umbral_effects(body,entry)
		"powers": _power_effects(body,entry)
		"passives":
			_heading(body,"Efeito do instinto")
			_paragraph(body,Content.PASSIVES[entry.id].description)
			_paragraph(body,"A passiva é individual; não substitui o traço da espécie.",true)
		"items":
			var item: Dictionary = Content.CONSUMABLES[entry.id]
			_heading(body,"Como usar")
			_paragraph(body,Items.effect_text(item, str(Content.ITEM_DESCRIPTIONS.get(entry.id, ""))))
			_paragraph(body,"Custa %d ação. Escolha o alvo pela mochila e confirme ao conjurar."%int(item.cost))
			_paragraph(body,"Fica na mochila, fora do baralho.",true)

func _umbral_effects(body: VBoxContainer, entry: Dictionary) -> void:
	if str(entry.species).is_empty():
		_heading(body,"Umbral de encontro")
		_paragraph(body,"Este registro reúne as memórias desse Umbral. Observe suas ações durante os encontros.")
		return
	var species: Dictionary = Content.SPECIES[entry.species]
	var individual = {"species":entry.species,"form_id":entry.form_id}
	_heading(body,str(Content.form_definition(entry.species, entry.form_id).trait))
	_paragraph(body,Content.trait_text(individual))
	_paragraph(body,"Resistências: "+Content.resistance_text(individual),true)
	body.add_child(Gold.line())
	_heading(body,"Poderes registrados")
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",18)
	grid.add_theme_constant_override("v_separation",14)
	body.add_child(grid)
	var powers: Array = species.powers.duplicate()
	if entry.form_id != Content.initial_form(entry.species): powers.append(species.signature)
	for id in powers:
		var known: bool = progress.knows("powers",id)
		var tile = VBoxContainer.new()
		tile.custom_minimum_size.x = 160
		tile.add_theme_constant_override("separation",8)
		grid.add_child(tile)
		var button = Plate.new()
		button.text = str(Content.POWERS[id].name).replace("\n"," ") if known else "???"
		button.accessibility_name = button.text
		button.disabled = not known
		button.custom_minimum_size = Vector2(160,110)
		button.plate = RefArt.region("ui/gold-codex-art",Rect2(955,705,103,106) if known and id == "fireball" else Rect2(1080,705,103,106))
		tile.add_child(button)
		if known and id != "fireball":
			var shade = ColorRect.new()
			shade.color = Gold.INK
			shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
			RefArt.native(button,shade,Rect2(8,8,144,94))
			var icon: TextureRect = RefArt.image(button,Assets.texture(Content.POWERS[id].art),Rect2(20,10,120,90))
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var label: Label = Gold.label(button.text,int(21*text_scale),Gold.PAPER,true)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(label)
		register.call(button,"codex.related."+str(id),"codex")
		button.pressed.connect(power_requested.emit.bind(str(id)))

func _power_effects(body: VBoxContainer, entry: Dictionary) -> void:
	var power: Dictionary = Content.POWERS[entry.id]
	_heading(body,"%d ação(ões) · %s"%[power.cost,Content.NATURES.get(power.get("nature",""),{}).get("name","")])
	var stats: Array[String] = []
	for field in ["damage","block","heal"]:
		if int(power.get(field,0)) > 0: stats.append("%s: %d"%[{"damage":"Potência","block":"Escudo","heal":"Cura"}[field],power[field]])
	_paragraph(body," · ".join(stats))
	var names = {"burn":"Queimadura","wet":"Encharcado","seed":"Semeado","electrified":"Interferência","taunt":"Provocação"}
	for condition in power.get("conditions",{}): _paragraph(body,"%s: %s"%[names.get(condition,condition),power.conditions[condition]])
	_paragraph(body,"Valores de catálogo, antes de atributos, passivas e evolução.",true)
