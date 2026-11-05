extends SceneTree
const Study = preload("res://tools/studies/pietro_house/study.tscn")
const Space = preload("res://scripts/ui/house_space.gd")
var checks: int = 0
var failed: int = 0
func expect(value: bool,label: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr(label)
func _init() -> void: call_deferred("run")
func snapshot(app: Control) -> String:
	return JSON.stringify([app.game.rng.state,app.game.party,app.session.run_save.load_snapshot(),app.session.stats])
func run() -> void:
	var study: Node = Study.instantiate()
	root.add_child(study)
	for i in range(8): await process_frame
	expect(study.initialized_host,"Experimental boot constructs the actual game and house")
	study.set_physics_process(false)
	var room: Control = study.room
	room.grab_focus()
	study._physics_process(0)
	expect(room.active and room.canvas.point==study.START and room.canvas.room=="living","Comparison starts on the real living-room floor")
	expect(room.canvas.background.resource_path.contains("pietro-house-continuous"),"Background comes from the production house binding")
	expect(study.brasa.form_id=="ember" and study.brasa.mesh.get_surface_count()>0 and study.brasa.texture.resource_path.contains("battle-creatures"),"Brasa is a live current-game mesh, not part of a plate")
	var before: String = snapshot(study.app)
	var point: Vector2 = room.canvas.point
	Input.action_press("umbral_refuge_right")
	for i in range(60): study._physics_process(1.0/60)
	Input.action_release("umbral_refuge_right")
	expect(absf(room.canvas.point.x-point.x-Space.SPEED)<0.01 and room.canvas.point.y==Space.FLOOR_Y,"Normal mode retains the real house speed and floor")
	expect(study.canvas.gather==1 and study.canvas.travelled>300,"The rig follows travelled world distance")
	point = room.canvas.point
	var camera: Vector2 = room.camera.center
	study.select("current")
	expect(not study.canvas.candidate and room.canvas.point==point and room.camera.center==camera,"A/B changes only the drawing at the same point and camera")
	study.select("candidate")
	study.select("pace")
	Input.action_press("umbral_refuge_right")
	for i in range(60): study._physics_process(1.0/60)
	Input.action_release("umbral_refuge_right")
	expect(absf(room.canvas.point.x-point.x-study.STUDY_SPEED)<0.01,"Explicit slow mode affects only the experiment callback")
	for i in range(30): study._physics_process(1.0/60)
	expect(study.canvas.gather==0 and study.canvas.cycle==0.5,"Stopping returns the approved neutral pose")
	Input.action_press("umbral_refuge_left")
	for i in range(18): study._physics_process(1.0/60)
	Input.action_release("umbral_refuge_left")
	expect(study.canvas.facing.x<0 and study.canvas.actor_bounds().size.x>0,"Reverse motion uses the mirrored candidate and valid bounds")
	expect(snapshot(study.app)==before,"Presentation comparison and walking preserve RNG, party, checkpoint and stats")
	expect(Space.SPEED==330 and study.BRASA.y==Space.FLOOR_Y,"Original movement constant and shared floor remain unchanged")
	print(JSON.stringify({"suite":"pietro_house_experiment","checks":checks,"failed":failed,"normal_speed":Space.SPEED,"study_speed":study.STUDY_SPEED,"base":"60b4e30","scope":"opt-in real-house composition, no production promotion"}))
	study.app.audio.shutdown()
	study.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(failed)
