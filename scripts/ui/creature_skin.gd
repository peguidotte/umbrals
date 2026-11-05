extends RefCounted
## Precomputed vertex weights and pose sampling; no node or gameplay state.
const ANGLES: Dictionary = {"head": 8, "tail": 9, "fore": 10, "hind": 11, "crest": 12, "ear": 13, "jaw": 14, "wing": 15, "feeler": 16, "bough": 17, "fin": 18, "wing_far": 16, "leg_far": 16, "arm_far": 17}
static func bind(uv: Vector2, definition: Dictionary, foot: Vector2) -> Dictionary:
	var bones: Array = []
	for joint in definition.get("joints", {}):
		var bone: Array = definition.joints[joint]
		var center: Vector2 = Vector2(float(bone[2]), float(bone[3]))
		var radius: Vector2 = Vector2(float(bone[4]), float(bone[5]))
		var weight: float = exp(-((uv - center) / radius).length_squared() * 1.35)
		if weight >= .005: bones.append([int(ANGLES.get(joint, 8)), uv - Vector2(float(bone[0]), float(bone[1])), weight])
	var family: String = str(definition.get("anatomy", {}).get("family", ""))
	var center: Vector2 = Vector2(.40, .37) if family == "dew" else Vector2(.44, .46) if family == "volt" else Vector2(.62, .61)
	var inflate: Vector2 = (uv - center) * exp(-((uv - center) / Vector2(.35, .38)).length_squared())
	var blink: float = 0.0
	if definition.has("anatomy"):
		var eye: Array = definition.anatomy.get("eye", [.7, .5])
		var eye_uv: Vector2 = Vector2(float(eye[0]), float(eye[1]))
		blink = (eye_uv.y - uv.y) * .9 * exp(-((uv - eye_uv) / Vector2(.065, .055)).length_squared() * 1.7)
	return {"uv": uv, "bones": bones, "inflate": inflate, "blink": blink, "plant": plant_weights(uv, definition), "bob_weight": pow(clampf((foot.y - uv.y) / maxf(.01, foot.y), 0, 1), .7)}

static func sample(binding: Dictionary, pose: Array, pose_rotations: Dictionary) -> Vector2:
	var result: Vector2 = binding.uv
	for bone in binding.bones:
		var channel: int = int(bone[0])
		if not pose_rotations.has(channel): continue
		var offset: Vector2 = bone[1]
		result += (pose_rotations[channel] * offset - offset) * float(bone[2])
	result += binding.inflate * float(pose[6])
	result.y += float(binding.blink) * float(pose[7])
	return result

static func plant_weights(uv: Vector2, definition: Dictionary) -> Array:
	var weights: Array = []
	for point in definition.get("walk_contacts", []):
		var at: Vector2 = Vector2(float(point[0]), float(point[1]))
		weights.append(exp(-((uv - at) / Vector2(.10, .08)).length_squared() * 4.0))
	return weights
