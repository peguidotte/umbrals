class_name UmbralContent
extends RefCounted
## Species, powers and individual passives, without runtime state.

const VERSION = "0.3.0"
const INITIAL_POWER_COPIES = 2
const STARTING_ITEMS = {"potion": 2, "revive": 1}
const CONSUMABLES = {
	"potion": {"name": "Poção", "cost": 1, "heal": 18},
	"revive": {"name": "Reanimar", "cost": 1, "revive_ratio": 0.35},
}
# Codex prose is presentation content; it grants no abilities or progression.
const UMBRAL_LORE = {
	"ember": {"title": "Quem guarda a última brasa", "text": "Brasa carrega a memória de uma fogueira mantida acesa à espera de alguém. Quando se assusta, recolhe a cauda em torno do corpo para proteger o próprio calor.\n\nAproxima-se em silêncio de quem sente frio. Seu primeiro gesto de confiança é dividir uma pequena chama."},
	"ignivar": {"title": "Uma chama que também guia", "text": "A chama que Brasa guardava junto ao corpo agora ilumina o caminho de outros Umbrals. Ignivar ainda para para ouvir o bosque antes de avançar.\n\nSuas caudas deixam um rastro de calor entre as árvores, como um farol para quem ficou para trás."},
	"moss": {"title": "Quem sempre deixa um abrigo pronto", "text": "Musgo guarda a lembrança de um santuário que acolheu viajantes. Seu corpo de madeira e folhas parece pesado, mas ele pisa com cuidado para não esmagar os brotos do caminho.\n\nAntes de descansar, ajeita um leito de folhas para os companheiros. Só então procura um lugar para si."},
	"verdalio": {"title": "O abrigo ganhou raízes", "text": "Em Verdálio, a memória do antigo santuário tornou-se uma copa viva. Pequenas flores crescem entre os galhos que ele curva para proteger quem se aproxima.\n\nConserva o hábito de Musgo: confere cada canto do abrigo antes de permitir que o bosque adormeça."},
	"volt": {"title": "Quem não consegue guardar uma tempestade", "text": "Faísca carrega a lembrança de um sino atingido por um raio. Impaciente, testa galhos com as antenas e às vezes se assusta com a própria descarga.\n\nA eletricidade encontra caminhos mais firmes quando ele está perto de outros Umbrals. Sozinho, continua procurando um eco que responda."},
	"tempestral": {"title": "O eco encontrou um caminho", "text": "As descargas inquietas de Faísca se organizam nos circuitos da carapaça de Tempestral. Suas antenas percorrem o ar como quem escuta uma tempestade distante.\n\nMesmo em repouso, mantém um brilho baixo para que seus companheiros saibam onde encontrá-lo."},
	"dew": {"title": "Quem recolhe o que a chuva lembra", "text": "Orvalho guarda gotas da primeira manhã depois da Fenda. Curioso, aproxima o rosto das poças para escutar as vibrações da água.\n\nQuando percebe tristeza em outro Umbral, oferece uma gota de seu reservatório. Depois espera, paciente, até que o silêncio pareça menos pesado."},
	"mareveu": {"title": "Um pequeno céu de água", "text": "A memória que Orvalho carregava em gotas se espalha pelos véus de Marevéu. A água acompanha seus movimentos sem perder a forma, refletindo a lua entre as árvores.\n\nAinda se demora junto às poças. Algumas lembranças só podem ser ouvidas quando tudo fica quieto."},
	"spore": {"title": "Um viajante das raízes", "text": "Esporo errante atravessa a clareira seguindo a umidade do chão. Seus passos espalham pequenos brilhos sob o chapéu, marcando trilhas que desaparecem quando o bosque seca.\n\nÉ fácil confundir sua imobilidade com distração. Ele está escutando o que se move debaixo das folhas."},
	"owl": {"title": "A vigília entre os espinhos", "text": "A Coruja dos espinhos repousa onde os galhos se cruzam. Imóvel, acompanha as passagens da floresta e só revela sua presença quando decide mudar de poleiro.\n\nAs penas lembram folhas secas; os olhos, porém, não deixam que nada se perca na escuridão."},
	"stag": {"title": "O Rei sem Aurora", "text": "O brilho de seus galhos surge entre as árvores antes que se ouçam seus passos. Os Umbrals da clareira se aquietam quando ele passa.\n\nNinguém sabe por quanto tempo ele vigia o bosque. À luz da lua, parece escutar uma manhã que ainda não chegou."},
}
const ITEM_DESCRIPTIONS = {
	"potion": "Uma pequena reserva de cuidado para as travessias do bosque. A poção recupera o fôlego de um Umbral ferido e segue na mochila até que o Guia escolha quem precisa dela.",
	"revive": "Quando um Umbral já não consegue continuar, este preparo ajuda a reacender seu vínculo. Reanima um companheiro incapacitado e devolve parte de seu HP.",
}
const POWER_DESCRIPTIONS = {
	"sowing": "Espalha uma semente sobre o alvo. Fogo, água e bosque podem dar destinos diferentes ao que foi plantado.",
	"interference": "Uma descarga desordena o ritmo do alvo. Além do impacto, a Interferência enfraquece seu próximo ataque.",
	"fireball": "Uma chama concentrada é lançada contra um alvo. Um golpe direto para abrir caminho entre as sombras do bosque.",
	"cinder_claw": "Brasas acompanham um golpe de garras. O calor permanece nos alvos atingidos mesmo depois do impacto.",
	"flame_guard": "Uma camada de cinzas protege quem conjura. O escudo ajuda a absorver os golpes da rodada.",
	"thorn_lash": "Um chicote de espinhos alcança os alvos enquanto o bosque prepara uma pequena proteção para quem o conduz.",
	"root_wall": "Raízes se erguem para proteger quem conjura. A barreira também provoca os oponentes.",
	"life_seed": "A energia de uma semente é dedicada à recuperação de um aliado ferido.",
	"lightning": "Um arco de eletricidade alcança um alvo. Água sobre o oponente pode abrir caminho para uma reação de Condução.",
	"static_veil": "Eletricidade envolve quem conjura, combinando proteção com uma descarga contra o alvo.",
	"storm_dive": "Um mergulho concentra a força da tempestade em um único alvo. Exige mais ações do que os golpes básicos.",
	"tidal_splash": "Um jato de água atinge e deixa o alvo Encharcado, preparando o terreno para outras técnicas.",
	"rain_sweep": "Uma cortina de chuva alcança posições vizinhas e deixa os oponentes atingidos Encharcados.",
	"dew_mend": "Uma gota preservada é compartilhada com um aliado para recuperar parte de seu HP.",
	"inferno": "A chama de Ignivar se expande sobre os oponentes. O impacto deixa queimaduras nos alvos atingidos.",
	"sanctuary": "Verdálio abre um abrigo para os aliados, unindo escudo e recuperação.",
	"judgment": "Tempestral espalha uma descarga pela formação adversária e prepara proteção para si.",
	"moon_tide": "A água de Marevéu atravessa a formação oponente, deixando os alvos atingidos Encharcados.",
}
const NATURES = {
	"fire": {"name": "Fogo", "color": "ef987b"},
	"water": {"name": "Água", "color": "80d7e5"},
	"lightning": {"name": "Raio", "color": "e8cf81"},
	"forest": {"name": "Bosque", "color": "91c8a1"},
}
const STARTERS = ["ember", "moss", "volt", "dew"]
# Short prototype routes make each starter's reactions reachable without a debug team.
const CAPTURE_ROUTES = {
	"ember": ["moss", "dew"], "moss": ["dew", "ember"],
	"volt": ["dew", "moss"], "dew": ["volt", "moss"],
}
const STAT_GROWTH = {"max_hp": 12, "attack": 3, "defense": 1, "speed": 2}
const SPECIES = {
	"ember": {"nature": "fire", "secondary_natures": ["", ""], "resistances": {"fire": 25}, "names": ["Brasa", "Ignivar"], "element": "Fogo", "color": "ef987b", "art": ["umbrals/ember", "umbrals/ignivar"], "trait": "Combustão", "trait_description": "Ataques aplicam %d queimadura.", "trait_values": [2, 4], "powers": ["fireball", "cinder_claw", "flame_guard"], "signature": "inferno", "stats": {"max_hp": 40, "attack": 10, "defense": 2, "speed": 14}},
	"moss": {"nature": "forest", "secondary_natures": ["", ""], "resistances": {"forest": 25}, "names": ["Musgo", "Verdálio"], "element": "Bosque", "color": "91c8a1", "art": ["umbrals/moss", "umbrals/verdalio"], "trait": "Raízes Vivas", "trait_description": "Ao proteger, cura %d por rodada.", "trait_values": [2, 4], "powers": ["thorn_lash", "root_wall", "sowing"], "signature": "sanctuary", "stats": {"max_hp": 48, "attack": 8, "defense": 4, "speed": 8}},
	"volt": {"nature": "lightning", "secondary_natures": ["", "water"], "resistances": {"lightning": 25}, "names": ["Faísca", "Tempestral"], "element": "Raio", "color": "e8cf81", "art": ["umbrals/volt", "umbrals/tempestral"], "trait": "Circuito Vivo", "trait_description": "Ataques: +%d dano por outro aliado ativo.", "trait_values": [4, 7], "powers": ["lightning", "interference", "storm_dive"], "signature": "judgment", "stats": {"max_hp": 36, "attack": 11, "defense": 1, "speed": 18}},
	"dew": {"nature": "water", "secondary_natures": ["", ""], "resistances": {"water": 25}, "names": ["Orvalho", "Marevéu"], "element": "Água", "color": "80d7e5", "art": ["umbrals/dew", "umbrals/mareveu"], "trait": "Maré Marcada", "trait_description": "Poderes de água deixam Encharcado por %d rodadas.", "trait_values": [2, 3], "powers": ["tidal_splash", "rain_sweep", "dew_mend"], "signature": "moon_tide", "stats": {"max_hp": 42, "attack": 9, "defense": 2, "speed": 20}},
}
const PASSIVES = {
	"fierce": {"name": "Feroz", "description": "Ataques ganham +3 dano."},
	"resilient": {"name": "Resiliente", "description": "Proteções ganham +3 escudo."},
	"vital": {"name": "Vital", "description": "Poderes de cura ganham +2 cura."},
	"ardent": {"name": "Ardente", "description": "Ataques aplicam +2 queimadura."},
	"swift": {"name": "Ágil", "description": "+3 Velocidade para este Umbral.", "speed_bonus": 3},
}
const PASSIVE_IDS = ["fierce", "resilient", "vital", "ardent", "swift"]
const PASSIVE_POOLS = {
	"ember": ["fierce", "resilient", "ardent", "swift"],
	"moss": ["fierce", "resilient", "ardent", "swift"],
	"volt": ["fierce", "ardent", "swift"],
	"dew": ["fierce", "vital", "swift"],
}
# Target describes the side; scope describes semantic slots, never front/back ranks.
# Larger priority resolves first. Order is only a stable per-power tiebreaker;
# water does not receive an implicit phase ahead of faster lightning owners.
const POWERS = {
	"sowing": {"nature": "forest", "learning": "nature", "conditions": {"seed": 3}, "name": "Semeadura", "cost": 1, "damage": 6, "block": 0, "heal": 0, "art": "attacks/life-seed", "target": "enemy", "scope": "single", "priority": 0, "order": 60},
	"interference": {"nature": "lightning", "learning": "nature", "conditions": {"electrified": 2}, "name": "Interferência", "cost": 1, "damage": 4, "block": 0, "heal": 0, "art": "attacks/lightning", "target": "enemy", "scope": "single", "priority": 0, "order": 80},
	"fireball": {"nature": "fire", "learning": "nature", "conditions": {}, "name": "Bola de\nfogo", "cost": 1, "damage": 12, "block": 0, "heal": 0, "art": "attacks/fireball", "target": "enemy", "scope": "single", "priority": 0, "order": 10},
	"cinder_claw": {"nature": "fire", "learning": "nature", "conditions": {"burn": 3}, "name": "Garra de\nbrasas", "cost": 1, "damage": 8, "block": 0, "heal": 0, "art": "attacks/cinder-claw", "target": "enemy", "scope": "upper_pair", "priority": 0, "order": 20},
	"flame_guard": {"nature": "fire", "learning": "nature", "conditions": {}, "name": "Manto de\ncinzas", "cost": 1, "damage": 0, "block": 8, "heal": 0, "art": "attacks/flame-guard", "target": "self", "scope": "single", "priority": 1, "order": 30},
	"thorn_lash": {"nature": "forest", "learning": "nature", "conditions": {}, "name": "Chicote de\nespinhos", "cost": 1, "damage": 8, "block": 4, "heal": 0, "art": "attacks/thorn-lash", "target": "enemy", "scope": "lower_pair", "priority": 0, "order": 40},
	"root_wall": {"nature": "forest", "learning": "nature", "conditions": {"taunt": 1}, "name": "Muralha de\nraízes", "cost": 1, "damage": 0, "block": 12, "heal": 0, "art": "attacks/root-wall", "target": "self", "scope": "single", "priority": 1, "order": 50},
	"life_seed": {"nature": "forest", "learning": "nature", "conditions": {}, "name": "Semente\nvital", "cost": 1, "damage": 0, "block": 0, "heal": 6, "art": "attacks/life-seed", "target": "ally", "scope": "single", "priority": 0, "order": 60},
	"lightning": {"nature": "lightning", "learning": "nature", "conditions": {}, "name": "Arco\nelétrico", "cost": 1, "damage": 11, "block": 0, "heal": 0, "art": "attacks/lightning", "target": "enemy", "scope": "single", "priority": 0, "order": 70},
	"static_veil": {"nature": "lightning", "learning": "nature", "conditions": {}, "name": "Véu\nestático", "cost": 1, "damage": 4, "block": 8, "heal": 0, "art": "attacks/static-veil", "target": "enemy", "scope": "single", "priority": 1, "order": 80},
	"storm_dive": {"nature": "lightning", "learning": "nature", "conditions": {}, "name": "Mergulho\ntrovão", "cost": 2, "damage": 25, "block": 0, "heal": 0, "art": "attacks/storm-dive", "target": "enemy", "scope": "single", "priority": 0, "order": 90},
	"tidal_splash": {"nature": "water", "learning": "nature", "conditions": {"wet": 2}, "name": "Jato de\norvalho", "cost": 1, "damage": 8, "block": 0, "heal": 0, "art": "attacks/splash", "target": "enemy", "scope": "single", "priority": 0, "order": 100},
	"rain_sweep": {"nature": "water", "learning": "nature", "conditions": {"wet": 2}, "name": "Chuva\nlateral", "cost": 1, "damage": 4, "block": 0, "heal": 0, "art": "attacks/rain", "target": "enemy", "scope": "upper_pair", "priority": 0, "order": 110},
	"dew_mend": {"nature": "water", "learning": "nature", "conditions": {}, "name": "Gota\nserena", "cost": 1, "damage": 0, "block": 0, "heal": 6, "art": "attacks/dew-mend", "target": "ally", "scope": "single", "priority": 0, "order": 120},
	"inferno": {"nature": "fire", "learning": "lineage", "conditions": {"burn": 5}, "name": "Sol\ndevorador", "cost": 2, "damage": 27, "block": 0, "heal": 0, "art": "attacks/inferno", "target": "enemy", "scope": "all", "priority": 0, "order": 130},
	"sanctuary": {"nature": "forest", "learning": "lineage", "conditions": {}, "name": "Santuário\nancestral", "cost": 2, "damage": 0, "block": 18, "heal": 6, "art": "attacks/sanctuary", "target": "ally", "scope": "all", "priority": 1, "order": 140},
	"judgment": {"nature": "lightning", "learning": "lineage", "conditions": {}, "name": "Juízo da\ntempestade", "cost": 2, "damage": 30, "block": 5, "heal": 0, "art": "attacks/judgment", "target": "enemy", "scope": "all", "priority": 0, "order": 150},
	"moon_tide": {"nature": "water", "learning": "lineage", "conditions": {"wet": 2}, "name": "Maré\nlunar", "cost": 2, "damage": 12, "block": 0, "heal": 0, "art": "attacks/rain", "target": "enemy", "scope": "all", "priority": 0, "order": 160},
}
# Legacy summary fields remain available to screens and migrated records. The
# playable battle uses individual enemies, not the legacy aggregate hp/intents.
const ENCOUNTERS = [
	{
		"id": "clearing", "name": "Esporo errante", "subtitle": "A FLORESTA EXPERIMENTA SEUS VÍNCULOS", "hp": 105, "intents": [7, 9, 6], "art": "characters/spore",
		"enemies": [
			{"uid": 1001, "species": "moss", "name": "Esporo errante", "art": "characters/spore", "stage": 1, "max_hp": 58, "hp": 58, "attack": 10, "defense": 0, "speed": 8, "slot": 1, "pattern": [
				{"nature": "forest", "conditions": {}, "category": "attack", "damage": 8, "block": 0, "wet": 0, "scope": "single"},
				{"nature": "forest", "conditions": {}, "category": "defend", "damage": 0, "block": 7, "wet": 0, "scope": "single", "priority": 1},
				{"nature": "forest", "conditions": {}, "category": "attack", "damage": 11, "block": 0, "wet": 0, "scope": "single", "target_policy": "weakest"},
			]},
		],
	},
	{
		"id": "thicket", "name": "Coruja dos espinhos", "subtitle": "UMBRALS NÃO LUTAM SOZINHOS", "hp": 170, "intents": [9, 12, 8], "art": "characters/owl",
		"enemies": [
			{"uid": 2001, "species": "volt", "name": "Coruja dos espinhos", "art": "characters/owl", "stage": 1, "max_hp": 46, "hp": 46, "attack": 10, "defense": 1, "speed": 14, "slot": 0, "pattern": [
				{"nature": "lightning", "conditions": {}, "category": "prepare", "charge": 6, "damage": 0, "block": 0, "wet": 0, "scope": "single"},
				{"nature": "lightning", "conditions": {}, "category": "attack", "damage": 7, "block": 0, "wet": 0, "scope": "upper_pair"},
				{"nature": "lightning", "conditions": {"electrified": 2}, "category": "attack", "damage": 6, "block": 0, "wet": 0, "scope": "single", "target_policy": "weakest"},
			]},
			{"uid": 2002, "species": "moss", "name": "Esporo vigia", "art": "characters/spore", "stage": 1, "max_hp": 40, "hp": 40, "attack": 10, "defense": 1, "speed": 8, "slot": 2, "pattern": [
				{"nature": "forest", "conditions": {"seed": 3}, "category": "attack", "damage": 4, "block": 0, "wet": 0, "scope": "single"},
				{"nature": "forest", "conditions": {}, "category": "defend", "damage": 0, "block": 8, "wet": 0, "scope": "single", "priority": 1},
				{"nature": "forest", "conditions": {}, "category": "attack", "damage": 6, "block": 0, "wet": 0, "scope": "lower_pair"},
			]},
		],
	},
	{
		"id": "boss", "name": "O Rei sem Aurora", "subtitle": "O ÚLTIMO ECO DO BOSQUE", "hp": 255, "intents": [11, 15, 9], "art": "characters/stag",
		"enemies": [
			{"uid": 3001, "species": "ember", "name": "O Rei sem Aurora", "art": "characters/stag", "stage": 2, "max_hp": 76, "hp": 76, "attack": 12, "defense": 2, "speed": 11, "slot": 1, "pattern": [
				{"nature": "fire", "conditions": {}, "category": "prepare", "charge": 6, "damage": 0, "block": 0, "wet": 0, "scope": "all"},
				{"nature": "fire", "conditions": {}, "category": "attack", "damage": 10, "block": 0, "wet": 0, "scope": "all"},
				{"nature": "fire", "conditions": {}, "category": "defend", "damage": 0, "block": 12, "wet": 0, "scope": "single", "priority": 1},
			]},
			{"uid": 3002, "species": "moss", "name": "Raiz do crepúsculo", "art": "characters/spore", "stage": 1, "max_hp": 40, "hp": 40, "attack": 10, "defense": 2, "speed": 6, "slot": 2, "pattern": [
				{"nature": "forest", "conditions": {}, "category": "defend", "damage": 0, "block": 8, "wet": 0, "scope": "single", "priority": 1},
				{"nature": "forest", "conditions": {"seed": 3}, "category": "attack", "damage": 4, "block": 0, "wet": 0, "scope": "lower_pair"},
				{"nature": "forest", "conditions": {}, "category": "attack", "damage": 6, "block": 0, "wet": 0, "scope": "single", "target_policy": "weakest"},
			]},
			{"uid": 3003, "species": "volt", "name": "Coruja da fenda", "art": "characters/owl", "stage": 1, "max_hp": 36, "hp": 36, "attack": 10, "defense": 0, "speed": 15, "slot": 0, "pattern": [
				{"nature": "lightning", "conditions": {}, "category": "attack", "damage": 5, "block": 0, "wet": 0, "scope": "single"},
				{"nature": "lightning", "conditions": {}, "category": "prepare", "charge": 6, "damage": 0, "block": 0, "wet": 0, "scope": "single"},
				{"nature": "lightning", "conditions": {}, "category": "attack", "damage": 7, "block": 0, "wet": 0, "scope": "upper_pair"},
			]},
		],
	},
]

static func species_stats(individual: Dictionary) -> Dictionary:
	var species_id: String = str(individual.get("species", "ember"))
	var data: Dictionary = SPECIES.get(species_id, SPECIES.ember)
	var stats: Dictionary = data.stats.duplicate(true)
	var growth: int = clampi(int(individual.get("stage", 1)) - 1, 0, 1)
	for key in STAT_GROWTH:
		stats[key] = int(stats[key]) + int(STAT_GROWTH[key]) * growth
	var passive: Dictionary = PASSIVES.get(str(individual.get("passive", "")), {})
	stats.speed = int(stats.speed) + int(passive.get("speed_bonus", 0))
	return stats

## Evolution upgrades these same instances. Signatures are learning options,
## never automatic extra cards. The rules own UIDs, ownership and card zones.
static func initial_power_ids(species_id: String) -> Array:
	var result: Array = []
	for power_id in SPECIES[species_id].powers:
		for _copy_number in range(INITIAL_POWER_COPIES):
			result.append(str(power_id))
	return result

static func display_name(umbral: Dictionary) -> String:
	return SPECIES[umbral.species].names[int(umbral.stage) - 1]

static func trait_text(umbral: Dictionary) -> String:
	var data: Dictionary = SPECIES[umbral.species]
	return data.trait_description % data.trait_values[int(umbral.stage) - 1]

static func natures(individual: Dictionary) -> Array[String]:
	var species: Dictionary = SPECIES[individual.species]
	var result: Array[String] = [str(species.nature)]
	var secondary: String = str(species.secondary_natures[clampi(int(individual.get("stage", 1)) - 1, 0, 1)])
	if not secondary.is_empty(): result.append(secondary)
	return result

static func nature_text(individual: Dictionary) -> String:
	var names: Array[String] = []
	for nature in natures(individual): names.append(str(NATURES[nature].name))
	return " / ".join(names)

static func resistances(individual: Dictionary) -> Dictionary:
	return individual.get("resistances", SPECIES[individual.species].resistances).duplicate(true)

static func resistance_text(individual: Dictionary) -> String:
	var labels: Array[String] = []
	var values: Dictionary = resistances(individual)
	for nature in NATURES:
		if int(values.get(nature, 0)) > 0: labels.append("%s −%d%%" % [NATURES[nature].name, int(values[nature])])
	return " · ".join(labels) if not labels.is_empty() else "Nenhuma"

static func can_learn(individual: Dictionary, power_id: String) -> bool:
	if not POWERS.has(power_id): return false
	var power: Dictionary = POWERS[power_id]
	if power.learning == "universal": return true
	if power.learning == "lineage": return SPECIES[individual.species].signature == power_id
	return str(power.nature) in natures(individual)

static func power_stats(power_id: String, stage: int) -> Dictionary:
	var stats: Dictionary = POWERS[power_id].duplicate(true)
	if stage == 2:
		if int(stats.damage) > 0: stats.damage = int(stats.damage) + 5
		if int(stats.block) > 0: stats.block = int(stats.block) + 4
		if int(stats.heal) > 0: stats.heal = int(stats.heal) + 2
		for id in ["burn", "wet"]:
			if int(stats.conditions.get(id, 0)) > 0: stats.conditions[id] = int(stats.conditions[id]) + 1
	# Compatibility summary fields; the resolver reads the condition catalog.
	for id in ["burn", "wet", "taunt"]: stats[id] = int(stats.conditions.get(id, 0))
	stats.lightning = stats.nature == "lightning"
	return stats
