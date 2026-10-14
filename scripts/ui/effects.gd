class_name UmbralEffects
extends Control
## A bounded presentation-only particle pool. Visual randomness never touches combat RNG.
var particles: Array = []
var projectiles: Array = []
var rng = RandomNumberGenerator.new()
var trauma: float = 0.0
var clock: float = 0.0
var reduced_motion: bool = false
var visual_layer: Control
var bursts: int = 0
var hits: int = 0
var flights: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.seed = 9127

func clear() -> void:
	particles.clear()
	projectiles.clear()
	trauma = 0
	if is_instance_valid(visual_layer): visual_layer.position = Vector2.ZERO
	queue_redraw()

func flight(from: Vector2, to: Vector2, color: Color) -> void:
	flights += 1
	if reduced_motion: return
	if projectiles.size() < 9: projectiles.append({"from": from, "to": to, "color": color, "age": 0.0, "duration": 0.22})

func burst(at: Vector2, color: Color, count: int = 14) -> void:
	bursts += 1
	if reduced_motion: return
	for i in range(mini(count, 64 - particles.size())):
		var angle: float = rng.randf_range(0, TAU)
		var velocity = Vector2(cos(angle), sin(angle)) * rng.randf_range(45, 160)
		particles.append({"p": at, "v": velocity, "life": rng.randf_range(0.25, 0.52), "age": 0.0, "color": color, "radius": rng.randf_range(1.5, 4)})

func impact(at: Vector2, magnitude: int) -> void:
	hits += 1
	trauma = minf(1, trauma + (0.60 if magnitude >= 35 else 0.30)) if not reduced_motion else 0.0
	burst(at, Color("edc986"), 24 if magnitude >= 35 else 12)

func _process(delta: float) -> void:
	var had_feedback: bool = trauma > 0 or not particles.is_empty() or not projectiles.is_empty()
	clock += delta
	trauma = maxf(0, trauma - delta * 2.5)
	if is_instance_valid(visual_layer):
		visual_layer.position = Vector2(sin(clock * 39), sin(clock * 51)) * 7 * trauma * trauma
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p.age += delta
		p.p += p.v * delta
		p.v *= pow(0.25, delta)
		if p.age >= p.life: particles.remove_at(i)
	for i in range(projectiles.size() - 1, -1, -1):
		projectiles[i].age += delta
		if projectiles[i].age >= projectiles[i].duration: projectiles.remove_at(i)
	if had_feedback or trauma > 0 or not particles.is_empty() or not projectiles.is_empty(): queue_redraw()

func _draw() -> void:
	for p in particles:
		var opacity: float = 1.0 - p.age / p.life
		draw_circle(p.p, p.radius * opacity, Color(p.color, opacity))
	for bolt in projectiles:
		var fraction: float = bolt.age / bolt.duration
		var eased: float = fraction * fraction * (3 - 2 * fraction)
		var point: Vector2 = bolt.from.lerp(bolt.to, eased) - Vector2(0, sin(fraction * PI) * 54)
		draw_circle(point, 16, Color(bolt.color, 0.15))
		draw_circle(point, 6, bolt.color)
		draw_circle(point, 2, Color("fff4ca"))
