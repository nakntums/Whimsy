extends Node2D

# typing challenge
@onready var typing_challenge = $TypingChallenge
@onready var boss = $Boss_1
var game_time := 0.0
var challenge_active := false
var initial_challenge_started := false
var boss_dead := false

# win sequence
@export var chest_scene: PackedScene 
@export var fairy_scene: PackedScene  
@export var dialogue_scene: PackedScene
@export var win_dialogue_path := "res://data/dialogue/level_one_win.json"

func _ready() -> void:
	$ColorRect/AnimationPlayer.play("fade_out")
	typing_challenge.hide()  # challenge starts hidden

	typing_challenge.challenge_started.connect(_on_challenge_started)
	typing_challenge.challenge_ended.connect(_on_challenge_ended)
	
	if boss:
		boss.boss_died.connect(_on_boss_died)

func _process(delta: float) -> void:
	game_time += delta
	# challenge starts at 10 seconds
	if game_time > 10.0 and not initial_challenge_started and not challenge_active and not boss_dead:
		start_typing_challenge()
		initial_challenge_started = true
	
	if game_time > 30.0 and challenge_active:
		end_typing_challenge()
		

func start_typing_challenge():
	challenge_active = true
	typing_challenge.start_challenge("easy")  # level 1 easy
	#print("FROM GAME.GD: TYPING CHALLENGE BEGINS")

func end_typing_challenge():
	challenge_active = false
	typing_challenge.stop_challenge()
	#print("FROM GAME.GD: TYPING CHALLENGE ENDS")

func _on_challenge_started():
	#print("Challenge started - updating boss state")
	if boss:
		boss.start_challenge()

func _on_challenge_ended():
	#print("Challenge ended - releasing boss state")
	challenge_active = false
	if boss:
		boss.end_challenge()

# win sequence boss dies -> chest spawns -> fairy spawns -> dialogue
func _on_boss_died(boss_position: Vector2):
	boss_dead = true
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

func _on_fairy_dialogue():
	var dialogue = dialogue_scene.instantiate()
	add_child(dialogue)
	dialogue.start_dialogue(win_dialogue_path) 
	await dialogue.dialogue_finished
	#print("GAME.GD: DIALOGUE FINISHED")

# for debugging
#func _on_typing_result(success: bool):
	#print("Word %s" % ["completed successfully!" if success else "failed!"])
