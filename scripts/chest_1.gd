extends Area2D  

signal chest_opened(position: Vector2) # emits signal to game.gd

@onready var animated_sprite = $AnimatedSprite2D
@onready var hint_label = $HintLabel

var is_open := false

func _ready():
	hint_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _input(event):
	if event.is_action_pressed("interact") and has_overlapping_bodies() and not is_open:
		_open_chest()

func _open_chest():
	is_open = true
	hint_label.visible = false
	animated_sprite.play("open") 
	await animated_sprite.animation_finished 
	emit_signal("chest_opened", global_position)
	
	queue_free()  
	
func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and not is_open:
		hint_label.visible = true

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		hint_label.visible = false
