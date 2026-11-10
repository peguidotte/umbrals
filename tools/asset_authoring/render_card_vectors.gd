extends SceneTree
## Native SVG importer produces reproducible transparent PNG components.
func _init() -> void:
	var inputs: PackedStringArray = OS.get_cmdline_user_args()
	if inputs.size() != 1:
		quit(2)
		return
	var plan: Variant = JSON.parse_string(FileAccess.get_file_as_string(inputs[0]))
	if not plan is Array:
		quit(2)
		return
	for item: Dictionary in plan:
		var image: Image = Image.new()
		var result: Error = image.load_svg_from_string(FileAccess.get_file_as_string(str(item.source)))
		if result != OK or image.save_png(str(item.destination)) != OK:
			push_error("Failed to render original card component: " + str(item.source))
			quit(1)
			return
	print(JSON.stringify({"rendered": plan.size()}))
	quit()
