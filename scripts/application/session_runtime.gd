extends RefCounted
## Coordinates one live Rules instance across session workflows. It handles
## command-to-checkpoint wiring; scene navigation and rendering remain signals.
const BattleInteraction = preload("res://scripts/application/battle_interaction.gd")
const BattleTurn = preload("res://scripts/application/battle_turn.gd")
const BattleCommands = preload("res://scripts/application/battle_commands.gd")
const ExpeditionFlow = preload("res://scripts/application/expedition_flow.gd")
const RewardFlow = preload("res://scripts/application/reward_flow.gd")
const RunFlow = preload("res://scripts/application/run_flow.gd")

signal game_changed(game: RefCounted)
signal screen_requested(screen: String)
signal screen_pop_requested
signal screen_refresh_requested
signal battle_refresh_requested
signal selection_refresh_requested
signal battle_requested
signal run_reset_requested(seed: int, fresh: bool)
signal practice_reset_requested(seed: int)
signal effects_clear_requested
signal continue_changed
signal focus_memory_requested(screen: String, key: String)
signal focus_requested
signal notice_requested(message: String)
signal reward_feedback_requested(individual: Dictionary, evolved: bool)
signal phase_requested
signal text_scale_requested
signal debug_requested
signal logged(event_name: String, details: Dictionary)

var interactions = BattleInteraction.new()
var turn = BattleTurn.new()
var commands = BattleCommands.new()
var expedition = ExpeditionFlow.new()
var rewards = RewardFlow.new()
var run = RunFlow.new()
var game: RefCounted
var screens: RefCounted
var audio: Node

func configure(next_game: RefCounted, session: RefCounted, codex: RefCounted, screen_stack: RefCounted, sound: Node, resolution: Callable) -> void:
	game = next_game
	screens = screen_stack
	audio = sound
	turn.configure(game, screens, audio, resolution)
	interactions.configure(game, turn, screens)
	commands.configure(game, turn, screens)
	expedition.configure(session, codex)
	rewards.configure(game, session)
	run.configure(session, expedition)
	_wire_interactions()
	_wire_turn()
	_wire_commands()
	_wire_expedition()
	_wire_rewards()
	_wire_run()

func bind_game(next_game: RefCounted) -> void:
	game = next_game
	turn.game = next_game
	interactions.game = next_game
	commands.game = next_game
	rewards.game = next_game
	game_changed.emit(next_game)

func _wire_interactions() -> void:
	interactions.screen_requested.connect(screen_requested.emit)
	interactions.screen_pop_requested.connect(screen_pop_requested.emit)
	interactions.cast_requested.connect(turn.cast)
	interactions.selection_refresh_requested.connect(selection_refresh_requested.emit)
	interactions.notice_requested.connect(notice_requested.emit)
	interactions.sound_requested.connect(_play_quiet_sound)

func _wire_turn() -> void:
	turn.selection_changed.connect(selection_refresh_requested.emit)
	turn.battle_changed.connect(_turn_battle_changed)
	turn.checkpoint_requested.connect(expedition.checkpoint)
	turn.result_requested.connect(_record_result)
	turn.phase_requested.connect(phase_requested.emit)
	turn.focus_requested.connect(focus_requested.emit)
	turn.text_scale_requested.connect(text_scale_requested.emit)
	turn.debug_requested.connect(debug_requested.emit)
	turn.logged.connect(logged.emit)

func _wire_commands() -> void:
	commands.screen_requested.connect(screen_requested.emit)
	commands.screen_pop_requested.connect(screen_pop_requested.emit)
	commands.screen_reset_requested.connect(screens.reset)
	commands.screen_refresh_requested.connect(screen_refresh_requested.emit)
	commands.battle_refresh_requested.connect(battle_refresh_requested.emit)
	commands.selection_refresh_requested.connect(selection_refresh_requested.emit)
	commands.checkpoint_requested.connect(expedition.checkpoint)
	commands.notice_requested.connect(notice_requested.emit)

func _wire_expedition() -> void:
	expedition.run_reset_requested.connect(run_reset_requested.emit)
	expedition.game_changed.connect(bind_game)
	expedition.battle_requested.connect(battle_requested.emit)
	expedition.screen_reset_requested.connect(screens.reset)
	expedition.map_refresh_requested.connect(screen_refresh_requested.emit)
	expedition.continue_changed.connect(continue_changed.emit)
	expedition.sound_requested.connect(_play_sound)
	expedition.logged.connect(logged.emit)

func _wire_rewards() -> void:
	rewards.screen_requested.connect(screen_requested.emit)
	rewards.screen_reset_requested.connect(screens.reset)
	rewards.screen_refresh_requested.connect(screen_refresh_requested.emit)
	rewards.battle_refresh_requested.connect(battle_refresh_requested.emit)
	rewards.focus_memory_requested.connect(focus_memory_requested.emit)
	rewards.checkpoint_requested.connect(expedition.checkpoint)
	rewards.sound_requested.connect(_play_sound)
	rewards.reward_feedback_requested.connect(reward_feedback_requested.emit)
	rewards.logged.connect(logged.emit)
	rewards.debug_requested.connect(debug_requested.emit)

func _wire_run() -> void:
	run.screen_push_requested.connect(screen_requested.emit)
	run.screen_pop_requested.connect(screen_pop_requested.emit)
	run.game_changed.connect(bind_game)
	run.practice_reset_requested.connect(practice_reset_requested.emit)
	run.battle_requested.connect(battle_requested.emit)
	run.effects_clear_requested.connect(effects_clear_requested.emit)
	run.screen_reset_requested.connect(screens.reset)
	run.logged.connect(logged.emit)

func _turn_battle_changed(_animated: bool) -> void:
	battle_refresh_requested.emit()

func _record_result() -> void:
	expedition.record_result(game)

func _play_sound(cue: String) -> void:
	audio.play(cue)

signal inspect_requested(index: int)
signal cast_requested
signal history_requested

func connect_overlays(overlays: RefCounted) -> void:
	overlays.back_requested.connect(screen_pop_requested.emit)
	overlays.remove_requested.connect(commands.remove_command)
	overlays.target_requested.connect(commands.plan_target)
	overlays.inspect_requested.connect(interactions.inspect_plan_power)
	overlays.clear_requested.connect(commands.clear_plan)
	overlays.cast_requested.connect(interactions.cast_from_plan)
	overlays.swap_requested.connect(commands.queue_swap)
	overlays.swap_cancel_requested.connect(commands.cancel_swap)
	overlays.formation_requested.connect(commands.draft_formation)
	overlays.formation_confirmed.connect(commands.commit_formation)
	overlays.item_requested.connect(commands.queue_item)
	overlays.item_cancel_requested.connect(commands.cancel_item)
	overlays.ko_requested.connect(commands.replace_ko)
	overlays.ko_finished.connect(commands.finish_ko)
	overlays.reward_requested.connect(rewards.take_reward)
	overlays.open_formation_requested.connect(commands.open_formation)
	overlays.history_requested.connect(interactions.open_history)
	overlays.replacement_requested.connect(rewards.choose_capture_destination)
	overlays.capture_slot_requested.connect(rewards.select_capture_slot)
	overlays.confirm_reward_requested.connect(rewards.accept_reward)

signal return_menu_requested
signal input_inspection_requested

func connect_input(router: RefCounted) -> void:
	router.debug_requested.connect(debug_requested.emit)
	router.selection_refresh_requested.connect(selection_refresh_requested.emit)
	router.finish_replacements_requested.connect(commands.finish_ko)
	router.screen_requested.connect(screen_requested.emit)
	router.screen_pop_requested.connect(screen_pop_requested.emit)
	router.return_menu_requested.connect(return_menu_requested.emit)
	router.card_requested.connect(turn.select)
	router.cast_requested.connect(turn.cast)
	router.redraw_requested.connect(turn.redraw)
	router.plan_requested.connect(interactions.open_plan)
	router.inspect_requested.connect(input_inspection_requested.emit)
	router.clear_requested.connect(commands.clear_plan)
	router.target_requested.connect(turn.cycle_target)

func _play_quiet_sound(cue: String, quiet: bool) -> void:
	audio.play(cue, quiet)
