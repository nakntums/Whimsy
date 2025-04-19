extends Area2D

signal dialogue_requested  # emits signal for game.gd

@onready var animated_sprite = $AnimatedSprite2D
@onready var hint_label = $HintLabel

var player_in_range := false  
@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	animated_sprite.play("idle")
	hint_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _input(event):
	if event.is_action_pressed("interact") and player_in_range:
		hint_label.visible = false
		_face_player()
		emit_signal("dialogue_requested")
		# disables multiple interactions
		set_process_input(false)

func _face_player():
	if player:
		animated_sprite.flip_h = (player.global_position.x < global_position.x)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		hint_label.visible = true
		player_in_range = true
		_face_player()
		#print("Player entered fairy's interaction zone") 

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		hint_label.visible = false
		player_in_range = false
		#print("Player left fairy's interaction zone")  
