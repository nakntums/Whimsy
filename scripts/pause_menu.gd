extends CanvasLayer

signal resume_game
signal restart_game
signal quit_game

func _ready() -> void:
	self.visible = false
	$Control/Button1.pressed.connect(_on_resume_pressed)
	$Control/Button2.pressed.connect(_on_restart_pressed)
	$Control/Button3.pressed.connect(_on_quit_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
# resume
func _on_resume_pressed():
	self.visible = false
	get_tree().paused = false
	resume_game.emit()

# retry
func _on_restart_pressed():
	self.visible = false
	get_tree().paused = false
	restart_game.emit()

# quit
func _on_quit_pressed():
	self.visible = false
	get_tree().paused = false
	quit_game.emit()
