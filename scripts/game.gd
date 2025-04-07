extends Node2D

@onready var typing_challenge = $TypingChallenge
@onready var boss = $Boss_1
var game_time := 0.0
var challenge_active := false
var initial_challenge_started := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ColorRect/AnimationPlayer.play("fade_out")
	typing_challenge.hide()  # challenge starts hidden

	typing_challenge.challenge_started.connect(_on_challenge_started)
	typing_challenge.challenge_ended.connect(_on_challenge_ended)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	game_time += delta
	# challenge starts at 10 seconds
	if game_time > 5.0 and not initial_challenge_started and not challenge_active:
		start_typing_challenge()
		initial_challenge_started = true
	
	if game_time > 40.0 and challenge_active:
		end_typing_challenge()

func start_typing_challenge():
	challenge_active = true
	typing_challenge.start_challenge("easy")  # level 1 easy
	print("FROM GAME.GD: TYPING CHALLENGE BEGINS")

func end_typing_challenge():
	challenge_active = false
	typing_challenge.stop_challenge()
	print("FROM GAME.GD: TYPING CHALLENGE ENDS")

func _on_challenge_started():
	print("Challenge started - updating boss state")
	if boss:
		boss.start_challenge()

func _on_challenge_ended():
	print("Challenge ended - releasing boss state")
	challenge_active = false
	if boss:
		boss.end_challenge()

# for debugging
func _on_typing_result(success: bool):
	print("Word %s" % ["completed successfully!" if success else "failed!"])

# prevent memory leaks
#func _exit_tree():
	#if typing_challenge.challenge_started.is_connected(_on_challenge_started):
		#typing_challenge.challenge_started.disconnect(_on_challenge_started)
	#if typing_challenge.challenge_ended.is_connected(_on_challenge_ended):
		#typing_challenge.challenge_ended.disconnect(_on_challenge_ended)
