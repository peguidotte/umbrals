extends RefCounted
const Presentation = preload("res://scripts/catalog/presentation_definition.gd")
const Clip = preload("res://scripts/catalog/clip_definition.gd")

static func validate(visual: Presentation) -> Array[String]:
	var errors: Array[String] = []
	if visual == null: return ["Missing presentation"]
	if visual.sound_id.is_empty(): errors.append("Missing event sound")
	for facing in ["left", "right"]:
		var direction = visual.direction(facing)
		if direction == null:
			errors.append("Missing direction: " + facing)
			continue
		if direction.portrait_path.is_empty(): errors.append("Missing portrait: " + facing)
		for anchor in ["mouth", "attack_origin", "impact_target", "center"]:
			if not direction.anchors.has(anchor): errors.append("Missing anchor: %s/%s" % [facing, anchor])
		for point in direction.anchors.values():
			if not point.is_finite() or point.x < 0 or point.x > 1 or point.y < 0 or point.y > 1:
				errors.append("Anchor must be a normalized finite point: " + facing)
		var seen: Dictionary = {}
		for clip in direction.clips:
			if clip == null:
				errors.append("Null animation clip")
				continue
			if clip.action_id not in Clip.ACTIONS or seen.has(clip.action_id): errors.append("Unknown/duplicate action: " + clip.action_id)
			seen[clip.action_id] = true
			if clip.mode not in ["procedural", "frames"]: errors.append("Unknown animation mode")
			if clip.mode == "frames" and clip.frames.is_empty(): errors.append("Frame animation is empty")
			if not is_finite(clip.duration) or clip.duration <= 0: errors.append("Clip duration must be positive")
			if not clip.pose_scale.is_finite() or not clip.pose_offset.is_finite() or clip.pose_scale.x <= 0 or clip.pose_scale.y <= 0:
				errors.append("Invalid procedural pose")
			if not clip.release_point.is_empty() and (not direction.anchors.has(clip.release_point) or not is_finite(clip.release_time) or clip.release_time < 0 or clip.release_time > clip.duration):
				errors.append("Invalid release event")
			if clip.action_id == "attack_ranged" and clip.release_point.is_empty(): errors.append("Ranged attack needs a release point/event")
		for action in Clip.ACTIONS:
			if not seen.has(action): errors.append("Missing action: %s/%s" % [facing, action])
	return errors
