extends RefCounted
## Numeric counters remain save-compatible; sources follow individuals, never slots.
const DEFINITIONS = {
	"burn": {"name": "Queima", "stack": "add", "decay": true, "description": "Dano ao HP no fim da rodada, ignora escudo; perde 1 intensidade."},
	"wet": {"name": "Encharcado", "stack": "refresh", "decay": true, "description": "Raio dobra a potência contra este alvo; não consome Encharcado."},
	"taunt": {"name": "Provocar", "stack": "refresh", "decay": true, "description": "Redireciona ataques individuais, sem alterar áreas."},
	"charge": {"name": "Carga", "stack": "add", "decay": false, "description": "Bônus de potência do próximo ataque; vale para todos os alvos da técnica."},
	"seed": {"name": "Semeado", "stack": "refresh", "decay": true, "description": "Bosque: Brotação (+6 escudo). Água: Floração (+8 HP). Fogo: Incêndio (+4 Queima). Consome a semente; benefícios vão à fonte original, sem reanimar."},
	"electrified": {"name": "Eletrificado", "stack": "refresh", "decay": true, "description": "Interferência: −25% de potência no próximo ataque, em todos os alvos. Não impede cura, defesa ou ações."},
}

static func apply(target: Dictionary, id: String, value: int, source: Dictionary = {}) -> void:
	if not DEFINITIONS.has(id) or value <= 0: return
	if not target.has("statuses"): target.statuses = {}
	if not target.has("status_sources"): target.status_sources = {}
	var previous: int = int(target.statuses.get(id, 0))
	target.statuses[id] = previous + value if DEFINITIONS[id].stack == "add" else maxi(previous, value)
	# Refreshing a seed never steals its original beneficiary.
	if previous <= 0 or id != "seed": target.status_sources[id] = source.duplicate(true)

static func consume(target: Dictionary, id: String) -> void:
	target.get("statuses", {}).erase(id)
	target.get("status_sources", {}).erase(id)

static func tick(target: Dictionary) -> void:
	# The caller advances only living active bodies. Reserve counters pause.
	for id in DEFINITIONS:
		if not bool(DEFINITIONS[id].decay) or not target.statuses.has(id): continue
		target.statuses[id] = maxi(0, int(target.statuses[id]) - 1)
		if int(target.statuses[id]) == 0: consume(target, id)

static func attack_multiplier(individual: Dictionary) -> float:
	return 0.75 if int(individual.get("statuses", {}).get("electrified", 0)) > 0 else 1.0

static func labels(individual: Dictionary, detailed: bool = false) -> Array[String]:
	var result: Array[String] = []
	for id in DEFINITIONS:
		var amount: int = int(individual.get("statuses", {}).get(id, 0))
		if amount <= 0: continue
		var label: String = str(DEFINITIONS[id].name)
		label += " +%d" % amount if id == "charge" else " %d" % amount if id == "burn" else " %dr" % amount
		if detailed: label += ": " + str(DEFINITIONS[id].description)
		result.append(label)
	return result
