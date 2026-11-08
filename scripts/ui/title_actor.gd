extends Button
## Decorative actor: bounded local timeline, no rules/session/storage dependency.
const Assets = preload("res://scripts/assets/catalog.gd")
const Content = preload("res://scripts/content.gd")
const BattleArt = preload("res://scripts/ui/battle_art.gd")
const CreatureRig = preload("res://scripts/ui/creature_rig.gd")
const Motion = preload("res://scripts/ui/battle_motion.gd")
const Gold = preload("res://scripts/ui/gold_theme.gd")
var choreography: Dictionary
signal activated
var species: String
var atlas: Texture2D
var support: Texture2D
var orb: Texture2D
var orb_layer: Control
var rig: Node2D
var grounding: Dictionary
var art_binding: String
var art_view: String
var clock: float = 0.0
var reaction: float = -1.0
var cooldown: float = 0.0
var reduced: bool = false
var frozen: bool = false
var flashes: bool = false
var compact: bool = false
var active: bool = true
var frame: int = 0
var reactions_started: int = 0

func build(identity: String) -> void:
	species = identity
	choreography = Assets.bound_manifest("ui/living-title-scene").metadata.actors[species]
	name = identity.capitalize()
	art_binding = str(choreography.art_binding)
	art_view = BattleArt.view_name(art_binding,species == "volt")
	atlas = BattleArt.texture(art_binding,art_view)
	grounding = BattleArt.ground_profile(art_binding,art_view)
	rig = CreatureRig.new()
	add_child(rig)
	rig.set_process(false)
	support = Assets.texture("ui/living-title-supports")
	if species == "dew":
		orb = Assets.texture("ui/living-title-orb")
		orb_layer = Control.new()
		orb_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(orb_layer)
		orb_layer.draw.connect(_draw_orb.bind(orb_layer))
	clock = {"ember":0.7,"moss":1.7,"dew":0.0,"volt":2.0}[species]
	accessibility_name = "Interagir com "+Content.display_name({"species":species,"stage":1})
	accessibility_description = "Uma reação decorativa; não inicia uma expedição."
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed","disabled","focus"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	pressed.connect(_react)
	for changed: Signal in [focus_entered,focus_exited,mouse_entered,mouse_exited]:
		changed.connect(queue_redraw)

func place(feet: Vector2, height: float, needs_support: bool) -> void:
	compact = needs_support
	height *= 1.12
	size = Vector2(height,height)
	position = feet-Vector2(height*0.5,height*0.9625)
	var source_foot: Vector2 = Vector2(float(grounding.foot[0]),float(grounding.foot[1]))
	var factor: float = height*0.86/maxf(1.0,source_foot.y-float(grounding.visible_top))
	var dimensions: Vector2 = atlas.get_size()*factor
	var pivot: Vector2 = source_foot*factor
	var mirrored: bool = species == "volt"
	rig.configure(atlas,species,dimensions,pivot,mirrored,art_view)
	if species == "dew":
		rig.definition = rig.definition.duplicate(true)
		rig.definition.joints.fore = [0.58,0.59,0.69,0.62,0.20,0.17]
		rig._build_topology()
	if mirrored: pivot.x = dimensions.x-pivot.x
	rig.position = size*Vector2(0.5,0.9625)-pivot
	_sync_pose()
	queue_redraw()

func set_active(value: bool) -> void:
	active = value
	disabled = not value
	mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE
	if not value: reaction = -1.0
	set_process(value)
	queue_redraw()

func apply_preferences(reduced_value: bool, freeze: bool, allow_flashes: bool) -> void:
	reduced = reduced_value
	frozen = freeze
	flashes = allow_flashes
	if reduced or frozen:
		reaction = -1.0
		frame = 0
	_sync_pose()
	queue_redraw()

func _react() -> void:
	if not active or reaction >= 0 or cooldown > 0: return
	reaction = 0.0
	reactions_started += 1
	activated.emit()
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree() or not active: return
	var elapsed: float = minf(delta,0.05)
	cooldown = maxf(0.0,cooldown-elapsed)
	if reaction >= 0:
		reaction += elapsed
		var duration: float = 0.5 if reduced else float(choreography.reaction.duration)
		frame = 8 if reduced else 8+mini(7,floori(reaction/duration*8.0))
		if reaction >= duration:
			reaction = -1.0
			cooldown = float(choreography.cooldown)
			frame = 0
			if species == "dew": clock = 0.0
	elif reduced or frozen: frame = 0
	else:
		clock += elapsed
		frame = floori(fmod(clock,float(choreography.idle.duration))/float(choreography.idle.duration)*8.0)
	if not reduced and not frozen:
		_sync_pose()
		queue_redraw()

func _sync_pose() -> void:
	if not is_instance_valid(rig) or rig.source == null: return
	rig.reduced_motion = reduced or frozen
	var pose: Array = Motion.neutral()
	if not reduced and not frozen:
		var wave: float = sin(clock*TAU/float(choreography.idle.duration))
		pose[5] = wave*0.45
		pose[9] = wave*0.025
		pose[13] = wave*0.018
		if species == "dew": pose[10] = -0.18+0.16*sin(_orb_phase()*TAU)
		if reaction >= 0:
			var weight: float = sin(clampf(reaction/float(choreography.reaction.duration),0,1)*PI)
			pose[8] = -weight*0.045
			pose[12] = weight*0.035
	rig.present_decorative_pose(pose)
	if is_instance_valid(orb_layer): orb_layer.queue_redraw()

func _has_point(point: Vector2) -> bool:
	if size.x <= 0: return false
	var local: Vector2 = (point-size*Vector2(0.5,0.52))/(size*Vector2(0.47,0.47))
	return local.length_squared() <= 1.0

func _draw() -> void:
	if atlas == null: return
	if compact:
		var index: int = {"ember":0,"moss":2,"dew":1,"volt":3}[species]
		var tile: Vector2 = Vector2(support.get_width()/2.0,support.get_height()/2.0)
		var surface: float = {"ember":0.35,"moss":0.40,"dew":0.45,"volt":0.35}[species]
		draw_texture_rect_region(support,Rect2(Vector2(-size.x*0.12,size.y*(0.9625-0.45*surface)),Vector2(size.x*1.24,size.y*0.45)),Rect2(Vector2(index%2,index/2)*tile,tile))
	_draw_local_effects()
	if active and (has_focus() or is_hovered()):
		draw_line(Vector2(size.x*0.35,size.y*0.96),Vector2(size.x*0.65,size.y*0.96),Gold.GOLD,maxf(2.0,size.y*0.009),true)

func _orb_phase() -> float:
	var phase: float = 0.0 if reduced or frozen else fmod(clock,1.05)/1.05
	if reaction >= 0 and not reduced: phase = fmod(reaction,0.60)/0.60
	return phase

func _draw_orb(target: CanvasItem) -> void:
	var phase: float = _orb_phase()
	var down: float = 0.0
	var squash: float = 1.0
	if phase < 0.36: down = pow(phase/0.36,2.0)
	elif phase < 0.44:
		down = 1.0
		squash = 0.85+0.15*absf(phase-0.40)/0.04
	else: down = pow((1.0-phase)/0.56,2.0)
	if reaction >= 1.2 and not reduced: down = down*1.20-0.20
	var diameter: float = size.y*0.24
	var center: Vector2 = Vector2(size.x*0.80,size.y*(0.59+0.2525*down))
	var dimensions: Vector2 = Vector2(diameter/sqrt(squash),diameter*squash)
	target.draw_set_transform(Vector2(size.x*0.80,size.y*0.9625),0,Vector2(1,0.22))
	target.draw_circle(Vector2.ZERO,diameter*(0.60-0.20*down),Color(0.01,0.05,0.10,0.10+0.25*down))
	target.draw_set_transform(Vector2.ZERO)
	target.draw_texture_rect(orb,Rect2(center-dimensions*0.5,dimensions),false)
	# A bounded local ripple; contact and the paw share this actor's timeline.
	if not reduced and not frozen and phase >= 0.36 and phase < 0.74:
		var progress: float = (phase-0.36)/0.38
		target.draw_set_transform(Vector2(size.x*0.80,size.y*0.9625),0,Vector2(1,0.20))
		target.draw_arc(Vector2.ZERO,size.y*(0.11+progress*0.12),0,TAU,32,Color(0.5,0.9,1.0,(1-progress)*0.6),maxf(1.0,size.y*0.008),true)
		target.draw_set_transform(Vector2.ZERO)

func _draw_local_effects() -> void:
	if reduced or frozen or not active: return
	if species == "ember" and reaction >= 0:
		for i in range(3):
			var progress: float = clampf((reaction-float(i)*0.14)/0.9,0.0,1.0)
			var point: Vector2 = size*Vector2(0.18+0.04*i+sin(progress*PI)*0.025,0.38-progress*0.20)
			draw_circle(point,maxf(1.0,size.y*0.007),Color(1.0,0.63,0.13,sin(progress*PI)*0.7))
	elif species == "moss" and reaction >= 0:
		var progress: float = clampf(reaction/1.7,0.0,1.0)
		var point: Vector2 = size*Vector2(0.29+progress*0.16,0.31-sin(progress*PI)*0.06)
		var radius: float = size.y*0.018
		draw_set_transform(point,sin(progress*PI)*0.6)
		draw_colored_polygon(PackedVector2Array([Vector2(-radius,0),Vector2(0,-radius*0.6),Vector2(radius,0),Vector2(0,radius*0.6)]),Color(0.72,0.88,0.24,sin(progress*PI)*0.8))
		draw_set_transform(Vector2.ZERO)
	elif species == "volt" and flashes:
		var phase: float = fmod(clock,7.0) if reaction < 0 else reaction
		if phase < 0.35:
			var alpha: float = sin(phase/0.35*PI)*0.7
			var arc: PackedVector2Array = [size*Vector2(0.66,0.22),size*Vector2(0.71,0.20),size*Vector2(0.70,0.25),size*Vector2(0.76,0.24)]
			draw_polyline(arc,Color(0.95,0.91,0.49,alpha),maxf(1.0,size.y*0.006),true)

func public_state() -> Dictionary:
	return {"species":species,"frame":frame,"reacting":reaction>=0,"reactions":reactions_started,"reduced":reduced,"active":active,"rect":[position.x,position.y,size.x,size.y],"art_binding":art_binding,"source_path":atlas.resource_path if not atlas is AtlasTexture else atlas.atlas.resource_path,"body_size":[rig.display_size.x,rig.display_size.y]}
