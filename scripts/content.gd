class_name UmbralContent
extends RefCounted
## Species, powers and individual passives, without runtime state.

const VERSION = "0.3.0"
const SPECIES = {
	"ember": {"names": ["Brasa", "Ignivar"], "element": "Fogo", "color": "ef987b", "art": ["ember", "ignivar"], "trait": "Combustão", "trait_description": "Ataques aplicam %d queimadura.", "trait_values": [2, 4], "powers": ["fireball", "cinder_claw", "flame_guard"], "signature": "inferno"},
	"moss": {"names": ["Musgo", "Verdálio"], "element": "Bosque", "color": "91c8a1", "art": ["moss", "verdalio"], "trait": "Raízes Vivas", "trait_description": "Ao proteger, cura %d por rodada.", "trait_values": [2, 4], "powers": ["thorn_lash", "root_wall", "life_seed"], "signature": "sanctuary"},
	"volt": {"names": ["Faísca", "Tempestral"], "element": "Raio", "color": "e8cf81", "art": ["volt", "tempestral"], "trait": "Circuito Vivo", "trait_description": "Ataques: +%d dano por outro aliado ativo.", "trait_values": [4, 7], "powers": ["lightning", "static_veil", "storm_dive"], "signature": "judgment"},
}
const PASSIVES = {
	"fierce": {"name": "Feroz", "description": "Ataques ganham +3 dano."},
	"resilient": {"name": "Resiliente", "description": "Proteções ganham +3 escudo."},
	"vital": {"name": "Vital", "description": "Poderes de cura ganham +2 cura."},
	"ardent": {"name": "Ardente", "description": "Ataques aplicam +2 queimadura."},
	"swift": {"name": "Ágil", "description": "−1 energia por rodada para este Umbral."},
}
const PASSIVE_IDS = ["fierce", "resilient", "vital", "ardent", "swift"]
const PASSIVE_POOLS = {
	"ember": ["fierce", "resilient", "ardent", "swift"],
	"moss": ["fierce", "resilient", "vital", "ardent", "swift"],
	"volt": ["fierce", "resilient", "ardent", "swift"],
}
const POWERS = {
	"fireball": {"name": "Bola de\nfogo", "cost": 1, "damage": 12, "block": 0, "heal": 0, "burn": 0, "art": "fireball"},
	"cinder_claw": {"name": "Garra de\nbrasas", "cost": 1, "damage": 8, "block": 0, "heal": 0, "burn": 3, "art": "claw"},
	"flame_guard": {"name": "Manto de\ncinzas", "cost": 1, "damage": 0, "block": 8, "heal": 0, "burn": 0, "art": "fire_guard"},
	"thorn_lash": {"name": "Chicote de\nespinhos", "cost": 1, "damage": 8, "block": 4, "heal": 0, "burn": 0, "art": "thorns"},
	"root_wall": {"name": "Muralha de\nraízes", "cost": 1, "damage": 0, "block": 12, "heal": 0, "burn": 0, "art": "roots"},
	"life_seed": {"name": "Semente\nvital", "cost": 1, "damage": 0, "block": 0, "heal": 6, "burn": 0, "art": "seed"},
	"lightning": {"name": "Arco\nelétrico", "cost": 1, "damage": 11, "block": 0, "heal": 0, "burn": 0, "art": "lightning"},
	"static_veil": {"name": "Véu\nestático", "cost": 1, "damage": 4, "block": 8, "heal": 0, "burn": 0, "art": "storm_guard"},
	"storm_dive": {"name": "Mergulho\ntrovão", "cost": 2, "damage": 25, "block": 0, "heal": 0, "burn": 0, "art": "dive"},
	"inferno": {"name": "Sol\ndevorador", "cost": 2, "damage": 27, "block": 0, "heal": 0, "burn": 5, "art": "inferno"},
	"sanctuary": {"name": "Santuário\nancestral", "cost": 2, "damage": 0, "block": 18, "heal": 6, "burn": 0, "art": "sanctuary"},
	"judgment": {"name": "Juízo da\ntempestade", "cost": 2, "damage": 30, "block": 5, "heal": 0, "burn": 0, "art": "judgment"},
}
const ENCOUNTERS = [
	{"name": "Esporo errante", "subtitle": "A FLORESTA EXPERIMENTA SEUS VÍNCULOS", "hp": 105, "intents": [7, 9, 6], "art": "spore"},
	{"name": "Coruja dos espinhos", "subtitle": "UMBRALS NÃO LUTAM SOZINHOS", "hp": 170, "intents": [9, 12, 8], "art": "owl"},
	{"name": "O Rei sem Aurora", "subtitle": "O ÚLTIMO ECO DO BOSQUE", "hp": 255, "intents": [11, 15, 9], "art": "stag"},
]

static func display_name(umbral: Dictionary) -> String:
	return SPECIES[umbral.species].names[int(umbral.stage) - 1]

static func trait_text(umbral: Dictionary) -> String:
	var data: Dictionary = SPECIES[umbral.species]
	return data.trait_description % data.trait_values[int(umbral.stage) - 1]

static func power_stats(power_id: String, stage: int) -> Dictionary:
	var stats: Dictionary = POWERS[power_id].duplicate(true)
	if stage == 2:
		if int(stats.damage) > 0: stats.damage = int(stats.damage) + 5
		if int(stats.block) > 0: stats.block = int(stats.block) + 4
		if int(stats.heal) > 0: stats.heal = int(stats.heal) + 2
		if int(stats.burn) > 0: stats.burn = int(stats.burn) + 1
	return stats
