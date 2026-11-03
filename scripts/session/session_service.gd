extends RefCounted
## Owns expedition checkpoint and result persistence independently of presentation.

const Expedition = preload("res://scripts/expedition/expedition.gd")
const RunSave = preload("res://scripts/session/run_save.gd")
const Storage = preload("res://scripts/storage.gd")
const SAVE_PATH: String = "user://umbral_stats_v1.json"
const LEGACY_SAVE_PATH: String = "user://feral_hand_stats.json"
const WEB_STATS_KEY: String = "umbral.stats.v1"

var run_save = RunSave.new()
var expedition = Expedition.new()
var expedition_active: bool = false
var saved_checkpoint: Dictionary = {}
var checkpoint_id: String = ""
var save_notice: String = ""
var recorded_expeditions: Array[String] = []
var persisted_expeditions: Array[String] = []
var checkpoint_writable: bool = true
var result_counted_in_memory: bool = false
var result_recorded: bool = false
var stats: Dictionary = {"wins": 0, "runs": 0, "best_damage": 0}

func load_stats() -> void:
	var data: Dictionary = Storage.read_json(SAVE_PATH, WEB_STATS_KEY, LEGACY_SAVE_PATH)
	for key in stats:
		if data.get(key) is float or data.get(key) is int: stats[key] = maxi(0, int(data[key]))
	if data.get("completed_expeditions") is Array:
		for id in data.completed_expeditions:
			if id is String and not id in recorded_expeditions: recorded_expeditions.append(id)
		while recorded_expeditions.size() > 128: recorded_expeditions.pop_front()
	persisted_expeditions.assign(recorded_expeditions)

func refresh_checkpoint(codex_progress: RefCounted) -> void:
	saved_checkpoint = run_save.load_snapshot()
	if not saved_checkpoint.is_empty():
		var candidate = Expedition.new()
		if not candidate.restore(saved_checkpoint):
			saved_checkpoint = {}
			save_notice = "O progresso salvo não pôde ser lido. Você pode iniciar uma nova expedição."
			run_save.last_status = "corrupt"
		else:
			codex_progress.observe(candidate.battle, candidate.phase in ["combat", "reward"])
		if str(saved_checkpoint.get("checkpoint_id", "")) in persisted_expeditions:
			saved_checkpoint = {}
			save_notice = "Esta expedição já foi encerrada. Comece um novo vínculo."
			run_save.clear()
		elif run_save.last_status == "recovered": save_notice = "Recuperamos o último progresso válido da expedição."
	elif run_save.last_status in ["corrupt", "io_error"]:
		save_notice = "Não foi possível ler o progresso salvo. Verifique o armazenamento do navegador ou inicie uma nova expedição."
	elif run_save.last_status == "incompatible":
		save_notice = "O progresso salvo pertence a outra versão e foi preservado. Uma nova expedição não poderá ser salva neste armazenamento."

func start_expedition(value: int, information_mode: String, starter: String) -> RefCounted:
	var previous: Dictionary = run_save.load_snapshot()
	checkpoint_writable = run_save.last_status != "incompatible"
	if not previous.is_empty() or run_save.last_status in ["corrupt", "io_error"]:
		checkpoint_writable = run_save.clear()
	expedition_active = true
	result_recorded = false
	result_counted_in_memory = false
	checkpoint_id = "%d-%d-%d" % [value, int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	expedition.new_run(value, information_mode, starter)
	return expedition.battle

func continue_expedition(codex_progress: RefCounted) -> bool:
	refresh_checkpoint(codex_progress)
	if saved_checkpoint.is_empty(): return false
	var candidate = Expedition.new()
	if not candidate.restore(saved_checkpoint): return false
	expedition = candidate
	checkpoint_writable = true
	expedition_active = true
	result_recorded = false
	result_counted_in_memory = false
	checkpoint_id = str(saved_checkpoint.get("checkpoint_id", "legacy-" + str(candidate.battle.seed_value)))
	return true

func start_practice() -> void:
	expedition_active = false
	result_recorded = false
	result_counted_in_memory = false

func record_result(game: RefCounted) -> bool:
	if result_recorded: return false
	var already_counted: bool = expedition_active and not checkpoint_id.is_empty() and checkpoint_id in recorded_expeditions
	if not already_counted and not result_counted_in_memory:
		result_counted_in_memory = true
		stats.runs = int(stats.runs) + 1
		if game.phase == "victory": stats.wins = int(stats.wins) + 1
		stats.best_damage = maxi(int(stats.best_damage), game.total_damage)
		if expedition_active:
			recorded_expeditions.append(checkpoint_id)
			while recorded_expeditions.size() > 128: recorded_expeditions.pop_front()
	var data: Dictionary = stats.duplicate()
	data["completed_expeditions"] = recorded_expeditions
	result_recorded = Storage.write_json(SAVE_PATH, WEB_STATS_KEY, data)
	if result_recorded: persisted_expeditions.assign(recorded_expeditions)
	else:
		save_notice = "Não foi possível salvar o resultado desta expedição."
		push_warning("Could not persist run statistics.")
	return true

func checkpoint(codex_progress: RefCounted) -> bool:
	if not expedition_active: return false
	codex_progress.observe(expedition.battle, expedition.phase in ["combat", "reward"])
	expedition.settle_battle()
	if expedition.phase in ["victory", "defeat"]:
		var attempted: bool = record_result(expedition.battle)
		if result_recorded:
			if not checkpoint_writable:
				save_notice = "Resultado salvo. Esta expedição foi jogada sem substituir o progresso anterior."
				return attempted
			if run_save.clear():
				saved_checkpoint = {}
				save_notice = "Expedição encerrada. Seus resultados foram salvos."
			else:
				var terminal: Dictionary = expedition.snapshot()
				terminal["checkpoint_id"] = checkpoint_id
				if run_save.save(terminal): save_notice = "Resultado salvo. O registro de conclusão será limpo ao voltar ao título."
				else: save_notice = "Resultado salvo. Não foi possível atualizar o progresso antigo; essa expedição concluída não poderá ser retomada."
			return attempted
	if not checkpoint_writable:
		if run_save.last_status == "incompatible":
			save_notice = "O progresso salvo pertence a outra versão e foi preservado. Esta nova expedição não será salva."
		else:
			save_notice = "Não foi possível substituir o progresso anterior. Esta nova expedição não será salva; o registro anterior foi preservado."
		return false
	var snapshot: Dictionary = expedition.snapshot()
	snapshot["checkpoint_id"] = checkpoint_id
	if run_save.save(snapshot):
		saved_checkpoint = snapshot
		save_notice = "Progresso salvo · você pode continuar pelo título."
	else:
		save_notice = "Não foi possível salvar. Você pode jogar, mas este avanço pode ser perdido ao fechar."
	return false
