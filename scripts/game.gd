extends Node2D

@onready var typing_challenge = $TypingChallenge
var game_time := 0.0
var challenge_active := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ColorRect/AnimationPlayer.play("fade_out")
	typing_challenge.hide()  # challenge starts hidden

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	game_time += delta
	# challenge starts at 10 seconds
	if game_time >= 10.0 and not challenge_active:
		start_typing_challenge()
	# challenge ends after 30 seconds
	if challenge_active and game_time >= 40.0:
		end_typing_challenge()
		
func start_typing_challenge():
	challenge_active = true
	typing_challenge.start_challenge("easy")  # level 1 easy
	typing_challenge.typing_completed.connect(_on_typing_result)

func end_typing_challenge():
	challenge_active = false
	typing_challenge.stop_challenge()
	# disconnect signal to prevent memory leaks
	if typing_challenge.typing_completed.is_connected(_on_typing_result):
		typing_challenge.typing_completed.disconnect(_on_typing_result)

# for debugging
func _on_typing_result(success: bool):
	if success:
		print("Word completed successfully!")
	else:
		print("Word failed!")

	
