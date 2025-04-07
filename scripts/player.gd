extends CharacterBody2D

# using a state machine 
enum PlayerState { 
	IDLE, 
	CASTING, 
	TYPING
	}
	
var current_state = PlayerState.IDLE

# direction and movement
var direction = 0
const SPEED = 250.0
const JUMP_VELOCITY = -400.0

# extended running logic
const MOVEMENT_THRESHOLD = 0.3
var time_moving = 0.0
const LOOP_FRAMES = [4, 5, 6]
var loop_frame_index = 0

# player health
@export var max_health : int = 9
@onready var current_health : int = max_health

# components
@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape : CollisionShape2D = $CollisionShape2D

# player hearts
@onready var health_ui = get_node("/root/Game/HealthUI")

# spells and cooldowns
@onready var flame_spell : Area2D = $skill_q
@onready var lightning_spell : Area2D = $skill_e 
@onready var ultimate_spell : Node2D = $skill_r
#@onready var flame_spell : PackedScene = preload("res://scenes/skill_q.tscn")
#@onready var lightning_spell : PackedScene = preload("res://scenes/skill_e.tscn")
#@onready var ultimate_spell : PackedScene = preload("res://scenes/skill_r.tscn")

@onready var timer_q : Timer = $timer_q
@onready var heal_cooldown_timer : Timer = $HealCooldownTimer
@onready var timer_e : Timer = $timer_e
@onready var timer_r : Timer = $timer_r

# combat mode 
var spell_direction = 1
var is_casting = false
var is_q_on_cooldown = false 
var is_w_on_cooldown = false 
var is_e_on_cooldown = false 
var is_r_on_cooldown = false 

# typing mode 
var is_typing_mode = false
var typed_text = ""
var typing_challenge = CanvasLayer

func _ready() -> void:
	loop_frame_index = 0 # reset frame index on start

	# connect cooldown timers
	timer_q.connect("timeout", Callable(self, "_on_q_cooldown_finished"))
	timer_e.connect("timeout", Callable(self, "_on_e_cooldown_finished"))
	timer_r.connect("timeout", Callable(self, "_on_r_cooldown_finished"))
	heal_cooldown_timer.connect("timeout", Callable(self, "_on_heal_cooldown_finished"))
	
	typing_challenge = get_node("/root/Game/TypingChallenge")
	if typing_challenge:
		typing_challenge.typing_completed.connect(_on_typing_result)
		typing_challenge.player_damaged.connect(take_damage)
		# connect letter correct/incorrect later if have time to add audio/visual feedback
	else: 
		push_warning("NO TYPING CHALLENGE FOUND")

func _physics_process(delta: float) -> void:
	if current_health <=0:
		die()
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += ProjectSettings.get("physics/2d/default_gravity") * delta
	else:
		velocity.y = 0 # sticks to floor
	
	
	if current_state == PlayerState.TYPING:
		animated_sprite.play("idle")
		velocity.x = 0
		move_and_slide()
		return
	
	if is_casting:
		return
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle horizontal movement manually
	if Input.is_action_pressed("left"):
		direction = -1
	elif Input.is_action_pressed("right"):
		direction = 1
	else:
		direction = 0

	velocity.x = direction * SPEED
	
	# handle idle and run animations
	if direction == -1:
		animated_sprite.scale.x = -1
	elif direction == 1:
		animated_sprite.scale.x = 1
	if direction == 0:
		if animated_sprite.animation == "dismount" and animated_sprite.frame == 3:
			animated_sprite.play("idle")  
	elif time_moving >= MOVEMENT_THRESHOLD and direction != 0:
		loop_frame_index = int(time_moving / 0.1) % LOOP_FRAMES.size()
		animated_sprite.frame = LOOP_FRAMES[loop_frame_index]
	else:
		animated_sprite.play("run")  # brief running

	if Input.is_action_pressed("attack_q") and !is_casting and !is_q_on_cooldown:
		start_casting("flame")
	if Input.is_action_pressed("attack_w") and !is_casting and !is_w_on_cooldown:
		start_casting("heal") 
	if Input.is_action_pressed("attack_e") and !is_casting and !is_e_on_cooldown:
		start_casting("lightning")
	if Input.is_action_pressed("attack_r") and !is_casting and !is_r_on_cooldown:
		start_casting("ultimate") 
		
	if direction == 0:
		time_moving = 0  # reset timer when player not moving and play dismount animation
		if animated_sprite.animation == "run" and !animated_sprite.is_playing():
			animated_sprite.play("dismount")
	else: 
		time_moving += delta
		
	# Move the sprite based on velocity
	move_and_slide()

# Combat mode spell casting 
func start_casting(spell_type: String) -> void:
	is_casting = true
	
	match spell_type:
		"flame":
			animated_sprite.play("cast_q")
			flame_spell.cast(animated_sprite.scale.x)
			is_q_on_cooldown = true
			timer_q.start(3.0)
		"heal":
			animated_sprite.play("cast_w")
			heal_cooldown_timer.start(7.0)
			is_w_on_cooldown = true
			# heal logic can remain in player script because it does not interact w/ boss hitboxes
			current_health = min(current_health + 1, max_health)
			if health_ui:
				health_ui.update_hearts(current_health)
			print("Healed! Current health: ", current_health)
		"lightning":
			animated_sprite.play("cast_e")
			timer_e.start(5.0)
			is_e_on_cooldown = true
			lightning_spell.cast(animated_sprite.scale.x)
		"ultimate":
			animated_sprite.play("cast_r")
			timer_r.start(1.0)
			is_r_on_cooldown = true
			ultimate_spell.cast(animated_sprite.scale.x)
	
	await animated_sprite.animation_finished 
	
	# handles player input spam
	if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		animated_sprite.play("run")  
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		animated_sprite.play("jump")  
	else:
		animated_sprite.play("idle")
	
	is_casting = false

func _on_q_cooldown_finished() -> void:
	is_q_on_cooldown = false
func _on_heal_cooldown_finished() -> void:
	is_w_on_cooldown = false
func _on_e_cooldown_finished() -> void:
	is_e_on_cooldown = false
func _on_r_cooldown_finished() -> void:
	is_r_on_cooldown = false

# typing logic 
func _input(event: InputEvent) -> void:
	# player presses ctrl and switches btw typing mode/idle mode
	if event.is_action_pressed("toggle_typing"):
		if current_state == PlayerState.TYPING:
			print("LEAVING TYPING MODE")
			current_state = PlayerState.IDLE
			typed_text = ""
			if typing_challenge:
				typing_challenge.set_process_input(false)  # disable typing challenge input
		else:
			current_state = PlayerState.TYPING
			print("CURRENTLY IN TYPING MODE")
			if typing_challenge:
				typing_challenge.set_process_input(true)  # enable typing challenge input
	
	# only process typing inputs if in typing mode
	if current_state != PlayerState.TYPING:
		return
	
	# feedback for debugging
	#if current_state == PlayerState.TYPING:
		#if event is InputEventKey and event.pressed and not event.echo:
			#var key = event.as_text()
			#if key.length() == 1:  # only capture single character keys
				#typed_text += key
				#print("Typed text: ", typed_text) 
				

func _on_typing_result(success: bool):
	if not success:
		print("player took 1 damage from failed typing")
		take_damage(1)

# taking damage logic 
func take_damage(amount: int) -> void:
	current_health -= amount
	if health_ui:
		health_ui.play_damage_effect()
		health_ui.update_hearts(current_health)
		
	for i in range(3):  # damage indicator
		animated_sprite.modulate = Color(1, 0, 0, 1)  
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color(1, 1, 1, 1) 
		await get_tree().create_timer(0.1).timeout
	#debug line
	print("Player took ", amount, " damage. Health: ", current_health)

func die() -> void:
	# prevents further input processing
	set_physics_process(false)
	set_process_input(false)
	
	if current_state == PlayerState.TYPING:
		current_state = PlayerState.IDLE
		if typing_challenge:
			typing_challenge.stop_challenge()
	
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	print("GAME OVER")
	#get_tree().change_scene_to_file("res://scenes/game_over.tscn")
	get_tree().call_deferred("change_scene_to_file", "res://scenes/game_over.tscn") # called next Idle frame
