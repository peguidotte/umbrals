extends RefCounted
## Intermediate art uses its own anatomy while keeping the existing individual.
const Motion = preload("res://scripts/ui/battle_motion.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
const Art = preload("res://scripts/ui/battle_art.gd")
const Rules = preload("res://scripts/rules.gd")
const Actor = preload("res://scripts/ui/actor.gd")

static func run(app: Control, expect: Callable) -> void:
	expect.call(Art.texture("umbrals/verdalio") == Assets.texture("umbrals/verdalio"),"Folife battle art uses the exact intermediate-hare pin")
	expect.call(Motion.form("verdalio").profile.name == "Folife" and Motion.form("moss").profile.name == "Foli","The two grass forms retain independent motion profiles")
	var unit: Dictionary = Rules.make_umbral("moss","resilient",1,"verdalio")
	var actor: Control = Actor.new()
	actor.size = Vector2(230,230)
	app.get_tree().root.add_child(actor)
	var bounds: Rect2 = actor.get_global_rect()
	for mirrored: bool in [false,true]:
		actor.enemy = mirrored
		actor.set_identity(unit)
		actor.rig.idle_time = 0.9
		actor.rig._refresh()
		var floor_at: Vector2 = actor.rig.to_global(actor.rig.project(actor.rig.foot))
		expect.call(floor_at.distance_to(actor.visual_ground())<0.25,"Folife idle and mirrored layout retain the authored foot anchor")
		for variant: int in [3,4,5]:
			actor.rig.seek_cast(variant,float(Motion.spec(variant).release),Vector2.ZERO)
			var emission: Vector2 = actor.emission_point(variant)
			expect.call(emission.is_finite() and actor.get_global_rect()==bounds,"Folife's own socket preserves the targetable slot")
			var direction: Vector2 = emission-actor.visual_ground()
			expect.call(direction.x<0 if mirrored else direction.x>0,"Folife's leaf/forepaw socket faces the opposing group")
			actor.rig.seek_cast(variant,3.2,Vector2.ZERO)
			expect.call(actor.rig.pose==Motion.neutral(),"Folife casts settle to the same ground pose")
	actor.queue_free()
	await app.get_tree().process_frame
	await preload("res://tests/support/foli_lifecycle_checks.gd").run(app,expect,Callable(),"verdalio")
