extends RefCounted
## A bounded second strike, owned by Lonelo. No extra card, unit, RNG or action.
const CatalogRevision = preload("res://scripts/battle/catalog_revision.gd")
const Content = preload("res://scripts/content.gd")
const BASE_POWER: int = 6
const REVISION: int = 6

static func available(owner: Dictionary, stats: Dictionary, revision: int) -> bool:
	return CatalogRevision.includes(revision, REVISION) and owner.get("species") == "dew" and Content.form_id(owner) == "lonelo" and int(owner.get("hp", 0)) > 0 and int(owner.get("slot", -1)) >= 0 and stats.get("nature") == "water" and stats.get("scope", "single") == "single" and stats.get("target", "enemy") == "enemy" and int(stats.get("damage", 0)) > 0

static func description() -> String:
	return "Companheira: segundo golpe de água com potência 6 no mesmo alvo, se sobreviver. Sem outra ação; defesa e resistência aplicam-se de novo. Não repete condições ou reações."

static func strike(target: Dictionary, multiplier: float) -> Dictionary:
	var resistance: int = clampi(int(Content.resistances(target).get("water", 0)), 0, 100)
	var damage: int = maxi(0, floori(BASE_POWER * multiplier * (1.0 - resistance / 100.0)) - int(target.defense))
	var absorbed: int = mini(int(target.block), damage)
	target.block -= absorbed
	damage = mini(int(target.hp), damage - absorbed)
	target.hp -= damage
	return {"amount": damage, "blocked": absorbed, "nature": "water", "resistance": resistance, "weakened": multiplier < 1.0, "amplified": false, "companion": true, "actor_name": "Companheira de Lonelo"}
