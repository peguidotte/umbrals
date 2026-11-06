class_name UmbralCodex
extends Control
## Owns category/page/selection and local Back history; child views emit requests.
const Gold = preload("res://scripts/ui/gold_theme.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
const RefArt = preload("res://scripts/ui/reference_art.gd")
const Plate = preload("res://scripts/ui/reference_button.gd")
const Catalog = preload("res://scripts/ui/codex/catalog.gd")
const Gallery = preload("res://scripts/ui/codex/gallery.gd")
const Record = preload("res://scripts/ui/codex/record.gd")
signal navigation_changed
var progress: RefCounted
var register: Callable
var category: String = "umbrals"
var selected: String = ""
var page: int = 0
var text_scale: float = 1.0
var catalog: Dictionary = {}
var canvas: Control
var tabs: Dictionary = {}
var entries: Gallery
var details: Record
var counter: Label
var page_label: Label
var previous: Button
var next: Button
var detail_scroll: ScrollContainer
var close: Button
var record_history: Array[Dictionary] = []
var context_revision: int = 0
var record_section: String = "story"
var current_entry: Dictionary = {}
const CATEGORY_RECTS = [Rect2(28,218,243,82),Rect2(28,301,243,82),Rect2(28,384,243,82),Rect2(28,467,243,82)]

func build(knowledge: RefCounted, registry: Callable, back: Callable, scale_value: float) -> void:
	name = "Overlay_codex"
	progress = knowledge
	register = registry
	text_scale = scale_value
	catalog = Catalog.build()
	canvas = Control.new()
	add_child(canvas)
	canvas.size = RefArt.SIZE
	RefArt.image(canvas, Assets.texture("ui/gold-codex-template"), Rect2(Vector2.ZERO,RefArt.SIZE))
	# Original title and botanical frame art, separate from interactive content.
	for rect in [Rect2(0,0,910,210), Rect2(0,210,282,680), Rect2(282,626,628,258), Rect2(882,210,28,680), Rect2(0,884,1250,57)]:
		RefArt.patch(canvas,"ui/gold-codex-art",rect)
	var nav_surface = ColorRect.new()
	nav_surface.color = Color("09191d")
	nav_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefArt.native(canvas,nav_surface,Rect2(28,218,243,331))
	var keys: Array = Catalog.CATEGORIES.keys()
	var labels: Array = Catalog.CATEGORIES.values()
	for i in range(keys.size()):
		var b = Plate.new()
		b.text = labels[i]
		b.text_zoom = 1.0
		b.accessibility_name = labels[i]
		b.plate = RefArt.region("ui/gold-codex-template",CATEGORY_RECTS[0] if i == 0 else CATEGORY_RECTS[1])
		b.selected = i == 0
		RefArt.native(canvas,b,CATEGORY_RECTS[i])
		RefArt.patch(b,"ui/gold-codex-art",Rect2(45,CATEGORY_RECTS[i].position.y+17,52,50),Rect2(14,16,46,46))
		_label(b,labels[i],Rect2(78,14,155,50),27)
		register.call(b,"codex.tab."+keys[i],"codex")
		b.pressed.connect(_choose_category.bind(keys[i]))
		tabs[keys[i]] = b
	counter = _label(canvas,"",Rect2(290,216,590,42),24,Gold.PAPER,true)
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	entries = Gallery.new()
	entries.setup(progress,register,text_scale)
	entries.entry_selected.connect(_select)
	RefArt.native(canvas,entries,Rect2(292,279,590,350))
	previous = _small_button("‹", Rect2(290,663,42,34),"codex.previous",_page.bind(-1))
	page_label = _label(canvas,"",Rect2(340,662,490,34),19,Gold.MUTED)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next = _small_button("›",Rect2(838,663,42,34),"codex.next",_page.bind(1))
	detail_scroll = ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	RefArt.native(canvas,detail_scroll,Rect2(910,0,762,880))
	details = Record.new()
	details.setup(progress,register,text_scale)
	details.section_requested.connect(_set_section)
	details.power_requested.connect(_open_power)
	details.form_requested.connect(_open_evolution)
	detail_scroll.add_child(details)
	close = Plate.new()
	close.text = "Voltar"
	close.text_zoom = 1.0
	close.accessibility_name = "Voltar"
	close.plate = RefArt.region("ui/gold-codex-art",Rect2(1484,884,170,42))
	RefArt.native(canvas,close,Rect2(1484,884,170,42))
	register.call(close,"codex.back","codex")
	close.pressed.connect(back)
	RefArt.patch(canvas,"ui/gold-codex-art",Rect2(1310,884,170,42))
	if not progress.saved_ok: _label(canvas,"Descobertas ainda não salvas",Rect2(940,885,350,35),18,Gold.GOLD)
	resized.connect(_layout)
	_category(category)
	_layout()

func _label(parent: Control, text: String, rect: Rect2, font_size: int, color: Color = Gold.PAPER, display: bool = true) -> Label:
	var result: Label = Gold.label(text,int(font_size * text_scale),color,display)
	RefArt.native(parent,result,rect)
	return result

func _small_button(text: String, rect: Rect2, id: String, callback: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size",24)
	b.add_theme_color_override("font_color",Gold.GOLD)
	for state in ["normal","hover","pressed","focus","disabled"]: b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	RefArt.native(canvas,b,rect)
	register.call(b,id,"codex")
	b.pressed.connect(callback)
	return b

func _ordered() -> Array:
	return Catalog.ordered(catalog,category,progress)

func _choose_category(key: String) -> void:
	# A deliberate tab change starts a new consultation.
	record_history.clear()
	_category(key)

func _sync_tabs() -> void:
	for tab in tabs:
		tabs[tab].selected = tab == category
		tabs[tab].plate = RefArt.region("ui/gold-codex-template",CATEGORY_RECTS[0] if tab == category else CATEGORY_RECTS[1])
		tabs[tab].queue_redraw()

func _category(key: String) -> void:
	context_revision += 1
	category = key
	record_section = "story"
	page = 0
	selected = ""
	_sync_tabs()
	_refresh()

func _page(delta: int) -> void:
	context_revision += 1
	page += delta
	_refresh()

func _refresh() -> void:
	var all: Array = _ordered()
	if selected.is_empty() and not all.is_empty(): selected = all[0].id
	var count: int = 0
	for entry in all:
		if progress.knows(category,entry.id): count += 1
	counter.text = ("%d / %d Umbrals descobertos" if category == "umbrals" else "%d / %d registros descobertos") % [count,all.size()]
	page = clampi(page,0,maxi(0,ceili(all.size()/float(Catalog.PAGE_SIZE))-1))
	previous.disabled = page == 0
	next.disabled = (page+1)*Catalog.PAGE_SIZE >= all.size()
	page_label.text = "%d / %d" % [page+1,maxi(1,ceili(all.size()/float(Catalog.PAGE_SIZE)))]
	entries.render(all.slice(page*Catalog.PAGE_SIZE,(page+1)*Catalog.PAGE_SIZE),category,selected)
	var entry: Dictionary = Catalog.find_entry(catalog,category,selected)
	if not entry.is_empty(): _detail(entry)
	_update_back_hint()
	navigation_changed.emit()

func _select(entry: Dictionary) -> void:
	context_revision += 1
	selected = entry.id
	record_section = "story"
	entries.select(selected)
	_detail(entry)
	_update_back_hint()
	navigation_changed.emit()

func _detail(entry: Dictionary) -> void:
	current_entry = entry
	detail_scroll.scroll_vertical = 0
	details.render(entry,category,record_section)

func _set_section(section: String) -> void:
	context_revision += 1
	record_section = section
	_detail(current_entry)
	navigation_changed.emit()
	# Tab controls are already in-tree. Restore immediately so a fast next
	# activation cannot have its focus stolen by a deferred tab restoration.
	_focus_record_section()

func _focus_record_section() -> void:
	# Rendering removes the activated link. Focus the destination synchronously,
	# after navigation_changed rebuilt its chain, before the next keyboard/pad event.
	for control in details.find_children("*","Control",true,false):
		if control.get_meta("ui_id","") == "codex.section."+record_section:
			control.grab_focus()
			return

func _open_power(id: String) -> void:
	_remember_record()
	_category("powers")
	selected = id
	var all: Array = _ordered()
	for i in range(all.size()):
		if all[i].id == id: page = i/Catalog.PAGE_SIZE
	_refresh()
	_focus_record_section()

func _open_evolution(id: String) -> void:
	if category == "umbrals" and selected == id: return
	var entry: Dictionary = Catalog.find_entry(catalog,"umbrals",id)
	if entry.is_empty(): return
	_remember_record()
	_select(entry)
	_focus_record_section()

func _remember_record() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	var focus_id: String = str(focused.get_meta("ui_id", "")) if is_instance_valid(focused) and is_ancestor_of(focused) else "codex.entry."+selected
	var record_name: String = "registro anterior"
	var entry: Dictionary = Catalog.find_entry(catalog,category,selected)
	if not entry.is_empty() and progress.knows(category,selected): record_name = str(entry.name)
	record_history.append({"category":category,"selected":selected,"page":page,"scroll":detail_scroll.scroll_vertical,"focus":focus_id,"name":record_name,"section":record_section})

func go_back() -> bool:
	if record_history.is_empty(): return false
	var origin: Dictionary = record_history.pop_back()
	context_revision += 1
	category = str(origin.category)
	record_section = str(origin.get("section","story"))
	selected = str(origin.selected)
	page = int(origin.page)
	_sync_tabs()
	_refresh()
	_restore_context(origin,context_revision)
	return true

func _restore_context(origin: Dictionary, revision: int) -> void:
	# The new controls already exist: return keyboard ownership before another input.
	var preferred: Control = tabs[category]
	for control in find_children("*","Control",true,false):
		var id: String = str(control.get_meta("ui_id",""))
		if id == "codex.entry."+selected: preferred = control
		if id == str(origin.focus) and control.is_visible_in_tree() and control.focus_mode != Control.FOCUS_NONE:
			if control is BaseButton and control.disabled: continue
			preferred = control
			break
	preferred.grab_focus()
	# Only scroll waits for layout. A quick Tab/click must keep its newer focus.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree() or revision != context_revision or not is_instance_valid(preferred) or not preferred.has_focus(): return
	detail_scroll.scroll_vertical = int(origin.scroll)
	detail_scroll.ensure_control_visible(preferred)

func _update_back_hint() -> void:
	if not is_instance_valid(close): return
	var destination: String = "Fechar o grimório" if record_history.is_empty() else "Voltar para "+str(record_history.back().name)
	close.tooltip_text = destination+" (Esc / B)"
	close.accessibility_name = destination

func _layout() -> void:
	if is_instance_valid(canvas): RefArt.layout(self,canvas)
