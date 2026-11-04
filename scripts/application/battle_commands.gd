extends RefCounted
## Owns reversible planning and the formation/replacement commands. The scene
## supplies the live Rules instance and reacts to the requested presentation.
signal screen_requested(screen: String)
signal screen_pop_requested
signal screen_reset_requested(screen: String)
signal screen_refresh_requested
signal battle_refresh_requested
signal selection_refresh_requested
signal checkpoint_requested
signal notice_requested(text: String)

var game: RefCounted
var turn: RefCounted
var screens: RefCounted
var reserve_uid: int = -1
var formation_draft: Array = [-1, -1, -1]

func configure(next_game: RefCounted, battle_turn: RefCounted, screen_stack: RefCounted) -> void:
	game = next_game
	turn = battle_turn
	screens = screen_stack

func plan_target(index: int, slot: int) -> void:
	if game.set_target(index, slot):
		turn.targeting_index = index
		selection_refresh_requested.emit()

func remove_command(kind: String, id: int) -> void:
	match kind:
		"power": game.toggle(id)
		"swap": game.cancel_swap(id)
		"item": game.cancel_item(id)
	selection_refresh_requested.emit()
	screen_refresh_requested.emit()

func clear_plan() -> void:
	if turn.busy: return
	game.clear_plan()
	turn.targeting_index = -1
	selection_refresh_requested.emit()
	if screens.top() == "plan": screen_refresh_requested.emit()

func open_reserve(index: int) -> void:
	if turn.busy or screens.top() != "battle": return
	var reserves: Array = game.reserves()
	if index < 0 or index >= reserves.size() or int(reserves[index].hp) <= 0: return
	reserve_uid = int(reserves[index].uid)
	screen_requested.emit("swap")

func queue_swap(slot: int) -> void:
	var occupant: Dictionary = {}
	for individual in game.party:
		if int(individual.get("slot", -1)) == slot:
			occupant = individual
			break
	var accepted: bool = game.queue_deploy(slot, reserve_uid) if occupant.is_empty() else game.queue_swap(int(occupant.uid), reserve_uid)
	if accepted:
		screen_pop_requested.emit()
		battle_refresh_requested.emit()
	else: notice_requested.emit("Não foi possível planejar essa troca. Confira ações e outras trocas.")

func cancel_swap(slot: int) -> void:
	game.cancel_swap(slot)
	screen_refresh_requested.emit()
	battle_refresh_requested.emit()

func open_formation() -> void:
	if turn.busy: return
	formation_draft = [-1, -1, -1]
	for individual in game.party:
		if int(individual.get("slot", -1)) >= 0: formation_draft[int(individual.slot)] = int(individual.uid)
	screen_requested.emit("formation")

func draft_formation(slot: int, uid: int) -> void:
	for i in range(3):
		if int(formation_draft[i]) == uid: formation_draft[i] = -1
	formation_draft[slot] = uid
	screen_refresh_requested.emit()

func commit_formation() -> void:
	if game.set_formation(formation_draft):
		screen_pop_requested.emit()
		turn.targeting_index = -1
		checkpoint_requested.emit()
		if screens.root() == "map": screen_refresh_requested.emit()
		else: battle_refresh_requested.emit()

func queue_item(item: String, uid: int) -> void:
	if turn.busy: return
	if game.queue_item(item, uid):
		screen_pop_requested.emit()
		battle_refresh_requested.emit()

func cancel_item(index: int) -> void:
	game.cancel_item(index)
	screen_refresh_requested.emit()
	battle_refresh_requested.emit()

func replace_ko(slot: int, uid: int) -> void:
	if game.replace_after_ko(slot, uid):
		checkpoint_requested.emit()
		battle_refresh_requested.emit()
		screen_refresh_requested.emit()

func finish_ko() -> void:
	if game.finish_replacements():
		checkpoint_requested.emit()
		screen_reset_requested.emit("battle")
		battle_refresh_requested.emit()
