extends Node2D

var button_type = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	button_type = "button"
	$ColorRect.show()
	$ColorRect/Fade_Timer.start()
	$ColorRect/AnimationPlayer.play("fade_in")
	

func _on_button_2_pressed() -> void:
	get_tree().quit()

func _on_fade_timer_timeout() -> void:
	if button_type == "button":
		get_tree().change_scene_to_file("res://scenes/game.tscn")
