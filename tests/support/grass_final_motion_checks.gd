extends RefCounted
## New final-form presentation never changes targeting or borrows a missing view.
const Actor = preload("res://scripts/ui/actor.gd")
const Rules = preload("res://scripts/rules.gd")
const Motion = preload("res://scripts/ui/battle_motion.gd")
const Art = preload("res://scripts/ui/battle_art.gd")
const Assets = preload("res://scripts/assets/catalog.gd")

static func run(app: Control, expect: Callable) -> void:
	var unit: Dictionary = Rules.make_umbral("moss","resilient",1,"foslash")
	var actor: Control = Actor.new()
	actor.size = Vector2(230,230)
	app.get_tree().root.add_child(actor)
	var bounds: Rect2 = actor.get_global_rect()
	expect.call(Art.texture("umbrals/foslash")==Assets.texture("umbrals/foslash"),"Foslash uses its pinned biped hare rather than an older atlas")
	expect.call(Motion.form("foslash").anatomy.name=="Foslash","Foslash has its own biped anatomy")
	expect.call(Art.view_name("umbrals/foslash",true)=="front" and Motion.form("foslash","back").is_empty(),"An absent rear view stays absent instead of inheriting front anatomy")
	for mirrored: bool in [false,true]:
		actor.enemy = mirrored
		actor.set_identity(unit)
		actor.rig.idle_time = 0.8
		actor.rig._refresh()
		var foot_at: Vector2 = actor.rig.to_global(actor.rig.project(actor.rig.foot))
		expect.call(foot_at.distance_to(actor.visual_ground())<0.25,"Foslash keeps the authored floor in both facings")
		for variant: int in [3,4,5]:
			actor.rig.seek_cast(variant,float(Motion.spec(variant).release),Vector2.ZERO)
			var primary: Vector2 = actor.emission_point(variant)
			var secondary: Vector2 = actor.emission_point(variant,true)
			expect.call(primary.is_finite() and secondary.is_finite() and primary.distance_to(secondary)>4,"Foslash leaf control follows its two distinct forepaws")
			expect.call(actor.get_global_rect()==bounds,"Foslash's cast leaves its targetable slot fixed")
			actor.rig.seek_cast(variant,3.2,Vector2.ZERO)
			expect.call(actor.rig.pose==Motion.neutral(),"Foslash's own cast returns to its resting pose")
	actor.queue_free()
	await app.get_tree().process_frame
	await preload("res://tests/support/foli_lifecycle_checks.gd").run(app,expect,Callable(),"foslash")
