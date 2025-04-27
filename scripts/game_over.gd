extends Node2D

var button_type = null

func _on_button_pressed() -> void:
	button_type = "button"
	$ColorRect.show()
	$ColorRect/Fade_Timer.start()
	$ColorRect/AnimationPlayer.play("fade_in")
	
func _on_button_2_pressed() -> void:
	get_tree().quit()

func _on_fade_timer_timeout() -> void:
	if button_type == "button":
		get_tree().change_scene_to_file(Global.current_level)
