extends Resource
@export var environment_id: String
@export_file("*.png", "*.svg") var background_path: String
@export var lighting: Color = Color(0.018, 0.038, 0.05, 0.10)
@export var firefly_color: Color = Color(0.98, 0.87, 0.57)
@export var music_id: String = "ambience"
@export var boss_music_id: String = "boss_pulse"
