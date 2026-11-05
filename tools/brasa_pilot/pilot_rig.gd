extends "res://scripts/ui/creature_rig.gd"
## Tool-only adapter. The production rig, projection and socket deformation remain the owner.
var walk_frames: Array = []
var walk_time: float = 0.0
var show_walk: bool = false

func _refresh() -> void:
	if not show_walk:
		super._refresh()
		return
	if texture == null or indices.is_empty(): return
	var sample_at: float = fposmod(walk_time, 1.0) * 30.0
	var first: int = floori(sample_at)
	pose = []
	for channel in range(walk_frames[0].size()):
		pose.append(lerpf(float(walk_frames[first][channel]), float(walk_frames[first + 1][channel]), sample_at - first))
	# Same public project() and mesh topology used by the production creature rig.
	var vertices: PackedVector2Array = PackedVector2Array()
	for row in range(GRID + 1):
		for column in range(GRID + 1):
			vertices.append(project(Vector2(float(column) / GRID, float(row) / GRID)))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	queue_redraw()
