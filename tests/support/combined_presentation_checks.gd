extends RefCounted
## Composition regression: grass clips and electric meshes share one actor slot.
const Rules = preload("res://scripts/rules.gd")
const Actor = preload("res://scripts/ui/actor.gd")

static func run(app: Control, expect: Callable) -> void:
	var actor: Control = Actor.new()
	actor.size = Vector2(230, 230)
	app.get_tree().root.add_child(actor)
	for form: String in ["moss", "verdalio", "volt", "tempestral", "auravel", "zuldar"]:
		var grass: bool = form in ["moss", "verdalio"]
		var healthy: Dictionary = Rules.make_umbral("moss" if grass else "volt", "resilient", 1, form)
		for mirror: bool in [false, true]:
			actor.enemy = mirror
			actor.set_identity(healthy)
			if grass:
				for group: String in ["states", "attacks", "reactions"]:
					for clip: int in ([0, 3, 6] if group == "states" else [3, 13, 14] if group == "attacks" else [0]):
						actor.rig.mode = group
						actor.rig.clip = clip
						actor.rig.elapsed = .7
						actor.rig.jump_scale = .63
						actor.rig.dash = Vector2(180, -12)
						actor.rig._refresh()
						var error: float = 0.0
						for binding: Dictionary in actor.rig.skin_bindings:
							error = maxf(error, actor.rig._project_cached(binding).distance_to(actor.rig.project(binding.uv)))
						expect.call(error < .0001, "Cached grass mesh agrees with direct projection for every vertex: " + form + "/" + str(mirror) + "/" + group + "/" + str(clip))
			var fallen: Dictionary = healthy.duplicate(true)
			fallen.hp = 0
			actor.set_identity(fallen)
			if grass:
				var life: Node2D = actor.rig.lifecycle
				expect.call(life.state == "ko" and life.sprite.frame == life.sprite.sprite_frames.get_frame_count(life.sprite.animation) - 1, "Restoring a grass KO snapshot selects the final frame immediately: " + form)
			else:
				expect.call(actor.rig.ko_mix > .99 and not actor.rig.lifecycle.active(), "Restoring an electric KO snapshot selects its own final mesh pose: " + form)
			actor.set_identity(healthy, 1.0, true)
			actor.rig._process(.1)
			var recovery_time: float = actor.rig.lifecycle.elapsed if grass else actor.rig.recovery_elapsed
			actor.set_identity(healthy, 1.0, true)
			expect.call(is_equal_approx(actor.rig.lifecycle.elapsed if grass else actor.rig.recovery_elapsed, recovery_time), "An ordinary identity refresh preserves the recovery clock: " + form)
			expect.call(actor.rig.lifecycle.state == "revive" if grass else actor.rig.recovery_elapsed >= 0.0, "Resetting transient mesh motion does not cancel recovery: " + form)
			var replacement: Dictionary = fallen.duplicate(true)
			replacement.uid = 9
			actor.set_identity(replacement, 1.0, true)
			expect.call(actor.rig.incapacitated and (actor.rig.lifecycle.state == "ko" and actor.rig.lifecycle.elapsed >= float(actor.rig.lifecycle.profile.ko_seconds) if grass else actor.rig.ko_mix > .99), "A different restored individual cannot inherit the previous recovery: " + form)
			actor.set_identity(healthy)
	actor.queue_free()
	await app.get_tree().process_frame
