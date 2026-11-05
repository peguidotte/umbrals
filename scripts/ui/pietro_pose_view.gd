extends RefCounted
## Cosmetic pose sampling only. No walking, collision, storage or game state.
const Assets = preload("res://scripts/assets/catalog.gd")
const Space = preload("res://scripts/ui/house_space.gd")
const BINDING = "characters/pietro-home-transitions"
const StairRig = preload("res://scripts/ui/pietro_stair_rig.gd")
var stair_rig: RefCounted = StairRig.new()
var base_texture: Texture2D = Assets.texture("characters/pietro-home")
var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Assets.bound_file("characters/pietro-home", "poses")))
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Assets.bound_file(BINDING, "poses")))
var textures: Dictionary = {
	"wake": Assets.texture(BINDING),
	"ascent": load(Assets.bound_file(BINDING, "ascent")) as Texture2D,
	"descent": load(Assets.bound_file(BINDING, "descent")) as Texture2D,
}

func sample(point: Vector2, facing: Vector2, stride: float, wake_phase: float, stairs: bool, stair_progress: float, stair_direction: float, reduced: bool) -> Dictionary:
	if wake_phase >= 0: return _wake(wake_phase)
	if stairs:
		var clip: String = "ascent" if stair_direction > 0 else "descent"
		if not reduced:
			stair_rig.seek(stair_progress, stair_direction)
			return {"rig": stair_rig, "pose": base.frames[int(base.idle)], "clip": clip, "index": int(fposmod(stair_progress * Space.STEPS, 2) * 4), "pose_name": "alternating_contacts"}
		var steps: float = stair_progress * Space.STEPS if stair_direction > 0 else (1.0 - stair_progress) * Space.STEPS
		var cycle: float = fposmod(steps, float(data.stair_steps_per_cycle)) / float(data.stair_steps_per_cycle)
		var index: int = 0 if reduced else mini(int(cycle * data.clips[clip].frames.size()), data.clips[clip].frames.size() - 1)
		return _clip(clip, index, point)
	var index: int = int(base.walk[int(stride) % base.walk.size()]) if stride > 0 else int(base.idle)
	return {"texture": base_texture, "pose": base.frames[index], "scale": float(base.source_scale), "anchor": point, "flip": facing.x < 0, "clip": "walk" if stride > 0 else "idle", "index": index, "pose_name": "walk" if stride > 0 else "idle"}

func _wake(phase: float) -> Dictionary:
	var clip: Dictionary = data.clips.wake
	var index: int = clip.frames.size() - 1
	for i in range(clip.frames.size()):
		if phase < float(clip.boundaries[i + 1]):
			index = i
			break
	var frame: Dictionary = clip.frames[index]
	var offset: Vector2 = Vector2(frame.bed_offset[0], frame.bed_offset[1])
	# Move the seated hips to the edge, then lower onto the floor. Do not rotate
	# a standing sprite or translate grounded boot poses while they straighten.
	if index in [2, 3]:
		var next: Array = clip.frames[index + 1].bed_offset
		var weight: float = smoothstep(float(clip.boundaries[index]), float(clip.boundaries[index + 1]), phase)
		offset = offset.lerp(Vector2(next[0], next[1]), weight)
	return _clip("wake", index, Space.BED + offset)

func _clip(clip: String, index: int, anchor: Vector2) -> Dictionary:
	var frame: Dictionary = data.clips[clip].frames[index]
	return {"texture": textures[clip], "pose": frame, "scale": float(data.clips[clip].scale), "anchor": anchor, "flip": false, "clip": clip, "index": index, "pose_name": frame.name}
