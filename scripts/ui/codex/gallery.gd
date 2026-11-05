extends Control
## One page of native gallery cards. The owner chooses data, page and record.
const Gold = preload("res://scripts/ui/gold_theme.gd")
const Art = preload("res://scripts/ui/battle_art.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
const RefArt = preload("res://scripts/ui/reference_art.gd")
const Plate = preload("res://scripts/ui/reference_button.gd")
const CardFrame = preload("res://scripts/ui/reference_card_frame.gd")
# Painted reference labels are valid only while they match the live catalog.
const PAINTED_NAMES = {"ember": "Brasa", "moss": "Musgo"}
signal entry_selected(entry: Dictionary)
var progress: RefCounted
var register: Callable
var text_scale: float = 1.0
var category: String
var selection_frames: Dictionary = {}

func setup(knowledge: RefCounted, registry: Callable, scale_value: float) -> void:
	progress = knowledge
	register = registry
	text_scale = scale_value

func render(items: Array, kind: String, selected_id: String) -> void:
	category = kind
	for child in get_children():
		remove_child(child)
		child.queue_free()
	selection_frames.clear()
	for slot in range(items.size()):
		var entry: Dictionary = items[slot]
		var known: bool = progress.knows(category,entry.id)
		var x: float = [0.0,196.0,378.0][slot]
		var card_size: Vector2 = [Vector2(176,306),Vector2(164,292),Vector2(168,292)][slot]
		var button = Plate.new()
		button.text = entry.name if known else "???"
		button.text_zoom = 1.0
		button.accessibility_name = entry.name if known else "Ainda não descoberto"
		RefArt.native(self,button,Rect2(Vector2(x,0 if slot == 0 else 6),card_size))
		button.plate = _card_picture(entry,known)
		if button.plate == null:
			var backdrop: TextureRect = RefArt.image(button,Assets.texture("ui/gold-codex-scene"),Rect2(Vector2(3,3),card_size-Vector2(6,6)))
			backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			backdrop.modulate = Color(0.45,0.55,0.55)
			var picture: TextureRect = RefArt.image(button,Art.texture(entry.art) if category == "umbrals" else Assets.texture(entry.art),Rect2(8,40,card_size.x-16,card_size.y-80))
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if category == "umbrals" else CanvasItem.TEXTURE_FILTER_LINEAR
		var frame = CardFrame.new()
		button.add_child(frame)
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.active = entry.id == selected_id
		selection_frames[entry.id] = frame
		var label: Label = _label(self,entry.name if known else "???",Rect2(x,310,card_size.x,38),26)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if known and category == "umbrals" and entry.name == PAINTED_NAMES.get(entry.id, "") and text_scale <= 1.0:
			label.modulate.a = 0
			var label_rect: Rect2 = Rect2(326,586,120,42) if entry.id == "ember" else Rect2(519,586,140,42)
			RefArt.patch(self,"ui/gold-codex-art",label_rect,Rect2(x+(34 if entry.id == "ember" else 31),307,label_rect.size.x,42))
		register.call(button,"codex.entry."+entry.id,"codex")
		button.pressed.connect(entry_selected.emit.bind(entry))

func select(id: String) -> void:
	for entry_id in selection_frames:
		selection_frames[entry_id].active = entry_id == id
		selection_frames[entry_id].queue_redraw()

func _label(parent: Control, text: String, rect: Rect2, font_size: int, color: Color = Gold.PAPER, display: bool = true) -> Label:
	var result: Label = Gold.label(text,int(font_size * text_scale),color,display)
	RefArt.native(parent,result,rect)
	return result

func _card_picture(entry: Dictionary, known: bool) -> Texture2D:
	if not known:
		return RefArt.region("ui/gold-codex-art",Rect2(670,285,168,292) if category == "umbrals" else Rect2(1080,705,103,106))
	if category == "umbrals" and not Assets.bound_manifest(entry.art).get("metadata", {}).get("battle_profile", {}).is_empty(): return null
	if category == "umbrals" and entry.id == "ember": return RefArt.region("ui/gold-codex-art",Rect2(292,279,176,306))
	if category == "umbrals" and entry.id == "moss": return RefArt.region("ui/gold-codex-art",Rect2(488,285,164,292))
	return null
