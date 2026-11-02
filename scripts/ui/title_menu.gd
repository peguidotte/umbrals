class_name UmbralTitleMenu
extends Control
const RefArt = preload("res://scripts/ui/reference_art.gd")
const Plate = preload("res://scripts/ui/reference_button.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
const KEYS = ["menu.play", "menu.codex", "menu.settings", "menu.help", "menu.credits", "menu.quit"]
const LABELS = ["INICIAR EXPEDIÇÃO", "GRIMÓRIO", "OPÇÕES", "COMO JOGAR", "CRÉDITOS", "SAIR"]
const RECTS = [Rect2(580,337,510,88), Rect2(580,425,510,67), Rect2(580,492,510,67), Rect2(580,559,510,67), Rect2(580,626,510,63), Rect2(580,689,510,58)]
signal card_awakened
signal navigation_requested
var buttons: Array[Button] = []
var input_active: bool = true
var reduced_motion: bool = false
var frozen: bool = false
var text_scale: float = 1.0
var canvas: Control
var selected_menu: int = 0
func build(callbacks: Array[Callable], register: Callable) -> void:
	name = "TitleScreen"
	canvas = Control.new()
	add_child(canvas)
	canvas.size = RefArt.SIZE
	# Fixed brand/environment atlas slices and individual command plates exactly
	# partition the approved composition; each command remains a native Button.
	for rect in [Rect2(0,0,1672,337), Rect2(0,337,580,410), Rect2(1090,337,582,410), Rect2(0,747,1672,194)]:
		RefArt.patch(canvas,"ui/gold-menu-art",rect)
	# The old subtitle is baked into the atlas. Restore the text-free forest
	# only behind that line, preserving the approved logo, leaves and controls.
	var brand_background: TextureRect = RefArt.patch(canvas,"ui/gold-menu-scene",Rect2(646,272,384,48))
	brand_background.modulate = Color(0.33,0.33,0.35)
	var feather = Shader.new()
	feather.code = """shader_type canvas_item;
void fragment() {
	vec2 edge = smoothstep(vec2(0.0), vec2(0.04, 0.24), UV)
		* smoothstep(vec2(0.0), vec2(0.04, 0.24), vec2(1.0) - UV);
	COLOR.a *= edge.x * edge.y;
}"""
	var blend = ShaderMaterial.new()
	blend.shader = feather
	brand_background.material = blend
	for i in range(callbacks.size()):
		if i == 5 and OS.has_feature("web"): continue
		var button = Plate.new()
		button.text = LABELS[i]
		button.accessibility_name = LABELS[i].capitalize()
		button.plate = RefArt.region("ui/gold-menu-art", RECTS[i])
		button.selected = i == 0
		RefArt.native(canvas, button, RECTS[i])
		button.pressed.connect(callbacks[i])
		button.focus_entered.connect(_select.bind(i))
		button.mouse_entered.connect(_select.bind(i))
		register.call(button, KEYS[i], "menu")
		buttons.append(button)
	resized.connect(_layout)
	_layout()
func _layout() -> void:
	if is_instance_valid(canvas): RefArt.layout(self, canvas)
func _select(index: int) -> void:
	if input_active and selected_menu != index:
		selected_menu = index
		navigation_requested.emit()
func apply_preferences(reduced: bool, freeze: bool, scale_value: float) -> void:
	reduced_motion = reduced
	frozen = freeze
	text_scale = scale_value
	for button in buttons:
		button.text_zoom = text_scale
		button.queue_redraw()
	_layout()
func effect_state() -> Dictionary:
	return {"reduced_motion": reduced_motion, "frozen": frozen, "clock":0, "card_poses":[], "background":"ui/gold-menu-scene", "portrait":size.x < 1000}
