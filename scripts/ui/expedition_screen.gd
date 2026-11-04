extends RefCounted
## Builds the map from a public expedition snapshot and emits player intents.
signal control_created(control: Control, id: String)
signal node_requested(id: String)
signal pause_requested
signal selection_changed(id: String)
signal formation_requested

const ExpeditionMap = preload("res://scripts/ui/expedition_map.gd")
var root: Control

func build(parent: Control, snapshot: Dictionary, text_scale: float, selection: String) -> Control:
	if is_instance_valid(root):
		root.hide()
		root.queue_free()
	var map = ExpeditionMap.new()
	root = map
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_margins(map)
	map.control_created.connect(control_created.emit)
	map.node_requested.connect(node_requested.emit)
	map.pause_requested.connect(pause_requested.emit)
	map.selection_changed.connect(selection_changed.emit)
	map.formation_requested.connect(formation_requested.emit)
	map.populate(snapshot, text_scale, selection)
	parent.add_child(map)
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_margins(map)
	return map

func _set_margins(map: Control) -> void:
	map.offset_left = 30
	map.offset_right = -30
	map.offset_top = 24
	map.offset_bottom = -24
