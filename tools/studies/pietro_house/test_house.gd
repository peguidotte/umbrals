extends SceneTree
const Study = preload("res://tools/studies/pietro_house/study.tscn")
const Space = preload("res://scripts/ui/house_space.gd")
var checks: int = 0
var failed: int = 0
var host_interference: float = 0
func expect(value: bool,label: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr(label)
func _init() -> void: call_deferred("run")
func snapshot(app: Control) -> String:
	return JSON.stringify([app.game.rng.state,app.game.party,app.session.run_save.load_snapshot(),app.session.stats])
func tick(study: Node,delta: float) -> void:
	study.room._physics_process(delta)
	var point: Vector2 = study.canvas.point
	var camera: Vector2 = study.room.camera.center
	study._physics_process(delta)
	host_interference = maxf(host_interference,point.distance_to(study.canvas.point)+camera.distance_to(study.room.camera.center))
func boot_vertex(study: Node,leg: int) -> Vector2:
	var rig: RefCounted = study.canvas.pilot
	var closest: int = -1
	var distance: float = INF
	var sole: Vector2 = Vector2(rig.data.legs[leg].sole[0],rig.data.legs[leg].sole[1])
	for i in range(rig.sources[leg].size()):
		if rig.sources[leg][i].y>1040 and rig.sources[leg][i].distance_to(sole)<distance:
			closest = i
			distance = rig.sources[leg][i].distance_to(sole)
	var vertices: PackedVector2Array = rig.legs[leg].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	return study.canvas.point+(vertices[closest]-Vector2(rig.data.pivot[0],rig.data.pivot[1]))*study.canvas.PILOT_SCALE
func run() -> void:
	var study: Node = Study.instantiate()
	root.add_child(study)
	for i in range(8): await process_frame
	expect(study.initialized_host,"Experimental boot constructs the actual game and house")
	expect(study.room.is_physics_processing(),"The real house retains its own automatic physics callback")
	study.set_physics_process(false)
	study.room.set_physics_process(false)
	var room: Control = study.room
	room.grab_focus()
	tick(study,0)
	expect(room.active and study.canvas.point==study.START,"Comparison starts on the real living-room floor")
	expect(study.canvas.background.resource_path.contains("pietro-house-continuous"),"The current house background binding is preserved")
	expect(study.brasa.form_id=="ember" and study.brasa.mesh.get_surface_count()>0 and study.brasa.texture.resource_path.contains("battle-creatures"),"Brasa is the current live creature renderer")
	expect(study.canvas.actor_layer.material!=null and study.canvas.material==null and study.brasa.material==null,"Hair grading is confined to the Pietro draw node")
	study.select("hair")
	expect(not study.canvas.soft_hair and is_zero_approx(study.canvas.actor_layer.material.get_shader_parameter("softness")),"Hair comparison disables only the local material strength")
	study.select("hair")
	var before: String = snapshot(study.app)
	var point: Vector2 = study.canvas.point
	var cycle: float = study.canvas.cycle
	var drift: float = 0
	var contact_samples: int = 0
	var prior: Array[Vector2] = [Vector2.INF,Vector2.INF]
	Input.action_press("umbral_refuge_right")
	for i in range(60):
		tick(study,1.0/60)
		for leg in range(2):
			var phase: float = fposmod(study.canvas.cycle+leg*0.5,1)
			if study.canvas.gather==1 and phase<0.5:
				var foot: Vector2 = boot_vertex(study,leg)
				if prior[leg]!=Vector2.INF:
					drift = maxf(drift,foot.distance_to(prior[leg]))
					contact_samples += 1
				prior[leg] = foot
			else: prior[leg] = Vector2.INF
	Input.action_release("umbral_refuge_right")
	var cadence: float = 2*(study.canvas.cycle-cycle)
	expect(absf(study.canvas.point.x-point.x-330)<0.01 and study.canvas.point.y==Space.FLOOR_Y,"Normal walking keeps 330 world pixels per second and the existing floor")
	expect(cadence>=2.8 and cadence<=3.2,"Normal movement measures about three steps per second, rather than 8.25")
	expect(contact_samples>20 and drift<0.001,"Actual support-boot mesh vertices stay planted with the longer stride")
	point = study.canvas.point
	var camera: Vector2 = room.camera.center
	study.select("current")
	expect(not study.canvas.candidate and study.canvas.point==point and room.camera.center==camera,"A/B retains the exact position and camera")
	study.select("candidate")
	study.select("motion")
	tick(study,0)
	expect(room.reduced and study.brasa.reduced_motion,"The actual reduced-motion preference reaches Pietro and Brasa")
	var brasa_clock: float = study.brasa.idle_time
	var brasa_mesh: PackedVector2Array = study.brasa.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	point = study.canvas.point
	Input.action_press("umbral_refuge_right")
	for i in range(60):
		tick(study,1.0/60)
		study.brasa._process(1.0/60)
	Input.action_release("umbral_refuge_right")
	expect(absf(study.canvas.point.x-point.x-330)<0.01,"Reduced motion retains the same logical movement speed")
	expect(study.canvas.gather==0 and study.canvas.cycle==0.5,"Pietro suppresses gait and secondary motion when reduced")
	var reduced_mesh_unchanged: bool = study.brasa.idle_time==brasa_clock and study.brasa.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==brasa_mesh
	expect(reduced_mesh_unchanged,"Brasa's clock and rendered mesh remain stationary under reduced motion")
	study.select("motion")
	tick(study,0)
	study.brasa._process(0.2)
	expect(not study.brasa.reduced_motion and study.brasa.idle_time>brasa_clock,"Brasa resumes normally after reduced motion is disabled")
	for i in range(30): tick(study,1.0/60)
	expect(study.canvas.gather==0 and study.canvas.cycle==0.5,"Stopping restores the approved neutral pose")
	Input.action_press("umbral_refuge_left")
	for i in range(18): tick(study,1.0/60)
	Input.action_release("umbral_refuge_left")
	expect(study.canvas.facing.x<0 and study.canvas.actor_bounds().size.x>0,"Reverse motion retains mirrored rendering and valid bounds")
	expect(host_interference==0,"The host never advances or rescales the house controller or camera")
	expect(snapshot(study.app)==before,"Walking and accessibility preserve RNG, party, checkpoint and stats")
	print(JSON.stringify({"suite":"pietro_house_experiment","checks":checks,"failed":failed,"logical_speed":330,"measured_steps_per_second":cadence,"support_mesh_drift_world_px":drift,"contact_samples":contact_samples,"host_controller_camera_interference":host_interference,"reduced_brasa_mesh_unchanged":reduced_mesh_unchanged,"base":"60b4e30"}))
	study.app.audio.shutdown()
	study.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(failed)
