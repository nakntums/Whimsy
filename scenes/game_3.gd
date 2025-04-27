extends Node2D

# pause game
var is_game_paused := false
@onready var pause_menu: CanvasLayer = $PauseMenu
@export var main_menu_scene: PackedScene

# player
@onready var player: CharacterBody2D = $Player

# typing challenge
@onready var typing_challenge: CanvasLayer = $TypingChallenge
@onready var boss: CharacterBody2D = $Boss_1
var game_time := 0.0
var challenge_active := false
var initial_challenge_started := false

# pre-fight sequence
var dialogue_active := false
@export var intro_dialogue := "res://data/dialogue/level_three_intro.json"

# win sequence
@export var chest_scene: PackedScene 
@export var fairy_scene: PackedScene  
@export var dialogue_scene: PackedScene # this handles all dialogues
@export var win_dialogue_path := "res://data/dialogue/level_three_win.json"

# default lose sequence
@onready var timer_label: Label = $Camera2D/TimerUI/TimerLabel
var time_limit := 60.0
var time_up := false
var boss_dead := false
@export var game_over_scene: PackedScene
@export var fail_dialogue_path := "res://data/dialogue/level_three_fail.json"

func _ready() -> void:
	$ColorRect/AnimationPlayer.play("fade_out")
	$ColorRect/AnimationPlayer.connect("animation_finished", Callable(self, "_on_fade_out_finished"))

	# pause set up
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	boss.process_mode = Node.PROCESS_MODE_PAUSABLE
	typing_challenge.process_mode = Node.PROCESS_MODE_PAUSABLE
	pause_menu.resume_game.connect(_on_resume)
	pause_menu.restart_game.connect(_on_restart)
	pause_menu.quit_game.connect(_on_quit)
	
	typing_challenge.hide()  # challenge starts hidden
	typing_challenge.challenge_started.connect(_on_challenge_started)
	typing_challenge.challenge_ended.connect(_on_challenge_ended)
	
	if boss:
		boss.boss_died.connect(_on_boss_died)
	
func _on_fade_out_finished(animation_name: String) -> void:
	if animation_name == "fade_out":
		$ColorRect/AnimationPlayer.disconnect("animation_finished", Callable(self, "_on_fade_out_finished"))  
		await show_intro_cutscene()
		
		
func show_intro_cutscene() -> void:
	dialogue_active = true
	freeze_characters(true) 
	var dialogue = dialogue_scene.instantiate()
	add_child(dialogue)
	dialogue.start_dialogue(intro_dialogue)
	await dialogue.dialogue_finished
	freeze_characters(false)
	#boss.handle_idle()
	#player.normalize()
	dialogue_active = false

func _process(delta: float) -> void:
	if dialogue_active or is_game_paused or boss_dead or time_up:
		return
	game_time += delta
	timer_label.text = "%02d:%02d" % [floor((time_limit - game_time) / 60), fmod(time_limit - game_time, 60)]
	
	# challenge starts at 10 seconds
	if game_time > 10.0 and not initial_challenge_started and not challenge_active and not boss_dead:
		start_typing_challenge()
		initial_challenge_started = true
	
	# challenge lasts 30 seconds
	if game_time > 40.0 and challenge_active:
		end_typing_challenge()
		
	if game_time >= time_limit and not boss_dead:
		time_up = true
		_on_time_limit_reached()

func start_typing_challenge():
	challenge_active = true
	typing_challenge.start_challenge("hard")  
	#print("FROM GAME.GD: TYPING CHALLENGE BEGINS")

func end_typing_challenge():
	challenge_active = false
	typing_challenge.stop_challenge()
	#print("FROM GAME.GD: TYPING CHALLENGE ENDS")

func _on_challenge_started():
	#print("Challenge started - updating boss state")
	if boss:
		boss.start_challenge()

func _on_challenge_ended(success: bool):
	#print("Challenge ended - releasing boss state")
	challenge_active = false
	if boss:
		boss.end_challenge(success)
		
func _on_time_limit_reached():
	# boss didn't die in stage time limit, auto fail
	if challenge_active:
		typing_challenge.stop_challenge(true)
	
	# "pause" game during lose sequence
	freeze_characters(true)
	
	# fail dialogue
	var dialogue = dialogue_scene.instantiate()
	add_child(dialogue)
	dialogue.start_dialogue(fail_dialogue_path)
	await dialogue.dialogue_finished
	
	# get game over 
	var game_over = game_over_scene.instantiate()
	get_tree().root.add_child(game_over)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = game_over

func freeze_characters(should_freeze: bool):
	if player:
		if should_freeze:
			player.fail_sequence()
		else:
			player.normalize()
		
	if boss:
		if should_freeze:
			boss.fail_sequence()
		else:
			boss.handle_idle()

# win sequence boss dies -> chest spawns -> fairy spawns -> dialogue
func _on_boss_died(boss_position: Vector2):
	boss_dead = true
	#print("saving player state: %d hp, %d mp", [player.current_health, player.current_mana])
	#print("BOSS DIED - ENDING CHALLENGE EARLY")
	if challenge_active:
		typing_challenge.stop_challenge(true)
	
	var chest = chest_scene.instantiate()
	add_child(chest)
	chest.global_position = boss_position
	chest.chest_opened.connect(_on_chest_opened)

func _on_chest_opened(chest_position: Vector2):
	var fairy = fairy_scene.instantiate()
	add_child(fairy)
	fairy.global_position = chest_position
	fairy.dialogue_requested.connect(_on_fairy_dialogue)
	await fairy_dialogue_finished
	fairy_leaves(fairy)

#flag to prevent multiple item add
var fairy_dialogue_triggered = false
#flag to prevent fairy from disappearing early
signal fairy_dialogue_finished
func _on_fairy_dialogue():
	if fairy_dialogue_triggered:
		return
	fairy_dialogue_triggered = true
	
	var dialogue = dialogue_scene.instantiate()
	add_child(dialogue)
	dialogue.start_dialogue(win_dialogue_path) 
	await dialogue.dialogue_finished
	emit_signal("fairy_dialogue_finished")
	var potion = preload("res://scenes/potion3.tscn").instantiate()
	var potion_scene_path = "res://scenes/potion3.tscn"
	player.inventory.add_item(potion, potion_scene_path)
	
func fairy_leaves(fairy: Node2D) -> void:
	var tween = fairy.create_tween()
	tween.tween_property(fairy, "modulate:a", 0, 2.0)
	await tween.finished
	fairy.queue_free()

func _on_exit_trigger_body_entered(body: Node2D) -> void:
	if body.name == "Player" and boss_dead:
		player.save_state()
		go_next_stage()

func go_next_stage():
	$ColorRect/AnimationPlayer.play("fade_in")
	await $ColorRect/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/game4.tscn")

# toggle pause
func _unhandled_input(event):
	if event.is_action_pressed("pause"):  
		toggle_pause()

func toggle_pause():
	is_game_paused = not is_game_paused
	get_tree().paused = is_game_paused
	pause_menu.visible = is_game_paused
	print("Paused:", is_game_paused)
	
	
func _on_resume():
	get_tree().paused = false
	pause_menu.visible = false
	
func _on_restart():
	get_tree().reload_current_scene()
	
func _on_quit():
	GameState.reset()
	get_tree().change_scene_to_packed(main_menu_scene)
