extends CharacterBody2D

var direction = 0
const SPEED = 250.0
const JUMP_VELOCITY = -400.0

# extended running
const MOVEMENT_THRESHOLD = 0.3
var time_moving = 0.0
const LOOP_FRAMES = [4, 5, 6]
var loop_frame_index = 0

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape : CollisionShape2D = $CollisionShape2D

# spells and cooldowns
@onready var flame_spell : Area2D = $skill_q
@onready var lightning_spell : Area2D = $skill_e 
@onready var ultimate_spell : Node2D = $skill_r
@onready var q_timer : Timer = $QTimer
@onready var e_timer : Timer = $ETimer
@onready var w_timer : Timer = $WTimer
@onready var r_timer : Timer = $RTimer

# combat mode input controls
var spell_direction = 1
var is_casting = false
var is_q_on_cooldown = false
var is_e_on_cooldown = false
var is_w_on_cooldown = false
var is_r_on_cooldown = false


func _ready() -> void:
	add_to_group("player") 
	loop_frame_index = 0 # reset frame index on start
	
	# spells are not visible until cast
	flame_spell.visible = false 
	flame_spell.position = Vector2(60, -20)
	
	lightning_spell.visible = false
	lightning_spell.position = Vector2(90, -50)
	
	ultimate_spell.visible = false  

	q_timer.connect("timeout", Callable(self, "_on_q_cooldown_finished"))
	e_timer.connect("timeout", Callable(self, "_on_e_cooldown_finished"))
	w_timer.connect("timeout", Callable(self, "_on_w_cooldown_finished"))
	r_timer.connect("timeout", Callable(self, "_on_r_cooldown_finished"))
	pass
	

func _physics_process(delta: float) -> void:	

	if is_casting:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += ProjectSettings.get("physics/2d/default_gravity") * delta
	
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
	if Input.is_action_pressed("attack_e") and !is_casting and !is_e_on_cooldown:
		start_casting("lightning")
	if Input.is_action_pressed("attack_w") and !is_casting and !is_w_on_cooldown:
		start_casting("heal") 
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
	
	if spell_type == "flame":
		is_q_on_cooldown = true
		spell_direction = animated_sprite.scale.x
		if spell_direction == 1:
			flame_spell.position = Vector2(60, -20)  
		else:
			flame_spell.position = Vector2(-60, -20)  
		animated_sprite.play("cast_q")
		flame_spell.visible = true  
		flame_spell.get_node("AnimatedSprite2D").play("skill_q")
		q_timer.start(3)
	elif spell_type == "lightning":
		is_e_on_cooldown = true
		spell_direction = animated_sprite.scale.x
		if spell_direction == 1:
			lightning_spell.position = Vector2(90, -50)  
		else:
			lightning_spell.position = Vector2(-90, -50)
		animated_sprite.play("cast_e")
		lightning_spell.visible = true  
		lightning_spell.get_node("AnimatedSprite2D").play("skill_e")
		e_timer.start(5)
	elif spell_type == "heal":
		is_w_on_cooldown = true
		spell_direction = animated_sprite.scale.x
		animated_sprite.play("cast_w")  
		w_timer.start(7)
	elif spell_type == "ultimate":
		is_r_on_cooldown = true
		spell_direction = animated_sprite.scale.x 
		animated_sprite.play("cast_r")  
		ultimate_spell.visible = true  

		ultimate_spell.get_node("SpellCircle").play("spell_circle")
		var laser_sprite = ultimate_spell.get_node("Laser").get_node("laser_attack")
		if laser_sprite:
			if spell_direction == -1:
				laser_sprite.position = Vector2(-260,80)
			else:
				laser_sprite.position = Vector2(260, 80)
			laser_sprite.scale.x = spell_direction
			laser_sprite.play("laser_attack")
			r_timer.start(10)
	
	await animated_sprite.animation_finished 
	

	if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		animated_sprite.play("run")  
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		animated_sprite.play("jump")  
	else:
		animated_sprite.play("idle")
	
	is_casting = false
	if spell_type == "flame":
		flame_spell.visible = false
	elif spell_type == "lightning":
		lightning_spell.visible = false
	elif spell_type == "ultimate":
		ultimate_spell.visible = false
	
func _on_q_cooldown_finished():
	is_q_on_cooldown = false
func _on_e_cooldown_finished():
	is_e_on_cooldown = false
func _on_w_cooldown_finished():
	is_w_on_cooldown = false
func _on_r_cooldown_finished():
	is_r_on_cooldown = false
