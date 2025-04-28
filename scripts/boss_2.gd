extends CharacterBody2D

signal boss_died(boss_position: Vector2)

enum BossState {
	IDLE,
	CHASING,
	CASTING,
	DEAD,
	CHALLENGE,
	STILL # for dialogue and vulnerable phase
}

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var player : CharacterBody2D = get_node("/root/Game/Player")

#@onready var water_spell_1 : Area2D = $water_spell_1
@onready var water_spell_1 : PackedScene = preload("res://scenes/fire_spell_1.tscn") 
#@onready var water_spell_2 : Area2D = $water_spell_2 
@onready var water_spell_2 : PackedScene = preload("res://scenes/fire_spell_2.tscn")  

@onready var timer_1 : Timer = $WaterSpell1Timer
@onready var timer_2 : Timer = $WaterSpell2Timer

# boss health 
@export var max_health : int = 20
@onready var current_health : int = max_health

# boss healh ui
@export var health_ui_scene: PackedScene
@export var boss_name := "Red Witch"
var health_ui: Node

# boss physics
var SPEED = 175.0 # increased speed  
const CHASE_RANGE = 1500.0 
const STOP_CHASE_RANGE = 75.0  
const JUMP_VELOCITY = -400.0  
const GRAVITY = 1200.0  

var current_state: BossState = BossState.IDLE
var previous_state: BossState 
var is_jumping = false

var can_cast = true
var is_1_on_cooldown = false
var is_2_on_cooldown = false

func _ready() -> void:
	animated_sprite.play("idle")
	
	if health_ui_scene:
		health_ui = health_ui_scene.instantiate()
		get_node("/root/Game/BossUI").add_child(health_ui)
		health_ui.init_boss(boss_name, max_health)
	
	timer_1.connect("timeout", Callable(self, "_on_1_cooldown_finished"))
	timer_2.connect("timeout", Callable(self, "_on_2_cooldown_finished"))
	
	var typing_challenge = get_node("/root/Game/TypingChallenge")
	if typing_challenge:
		typing_challenge.challenge_started.connect(start_challenge)
		typing_challenge.challenge_ended.connect(end_challenge)
	else:
		push_warning("NO TYPING CHALLENGE FOUND")

func _physics_process(delta: float) -> void:

	if current_health <= 0:
		die()
		
	if current_state != BossState.DEAD:
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		else:
			velocity.y = 0
			is_jumping = false
	
	match current_state:
		BossState.IDLE:
			handle_idle()
		BossState.CHASING:
			handle_chasing(delta)
		BossState.CASTING:
			pass
		BossState.CHALLENGE:
			handle_challenge()
		BossState.STILL:
			handle_still()
		BossState.DEAD:
			return
	
	# only cast skills in a state that allows it
	if current_state in [BossState.IDLE,BossState.CHASING]:
		try_cast_skill()
	
	move_and_slide()
	
func start_challenge():
	current_state = BossState.CHALLENGE
	print("BOSS HAS ENTERED CHALLENGE STATE")

func end_challenge(success: bool) -> void:
	if success:
		previous_state = current_state
		current_state = BossState.STILL
		print("CHALLENGE SUCCESS: BOSS IS DIZZY!")
		start_blinking_effect(7.0)
		await get_tree().create_timer(7.0).timeout
		recover_from_still()
	else:
		current_state = BossState.IDLE
		animated_sprite.play("idle")
		print("CHALLENGE NEUTRAL: BOSS IS UNFAZED BY YOUR PERFORMANCE")
		await get_tree().process_frame # small cooldown for processing
		handle_idle()
	
func handle_challenge() -> void:
	velocity = Vector2.ZERO
	animated_sprite.play("charge")

func handle_still() -> void:
	animated_sprite.play("idle")
	can_cast = false
	velocity = Vector2.ZERO

func fail_sequence() -> void:
	current_state = BossState.STILL 

func recover_from_still() -> void:
	current_state = BossState.IDLE
	can_cast = true
	modulate = Color.WHITE
	
func start_blinking_effect(duration: float) -> void:
	blink_dizzy(duration)

func blink_dizzy(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		animated_sprite.modulate = Color(0.9, 0.7, 0.1, 1.0)
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color(1, 1, 1, 1)
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.2

func handle_idle() -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < CHASE_RANGE:
		current_state = BossState.CHASING
		return # immediately transitions to chasing
	
	# default idle behavior
	animated_sprite.play("idle")
	velocity = Vector2.ZERO

func handle_chasing(delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= STOP_CHASE_RANGE:
		current_state = BossState.IDLE
		velocity.x = 0
		animated_sprite.play("idle")
		return
	
	var direction_to_player = (player.position - position).normalized()
	velocity.x = direction_to_player.x * SPEED
	
	if direction_to_player.x > 0:
		animated_sprite.scale.x = 1 
	elif direction_to_player.x < 0:
		animated_sprite.scale.x = -1  
	
	if is_on_floor() and not is_jumping and position.y > player.position.y + 100:
		velocity.y = JUMP_VELOCITY
		is_jumping = true
	
	animated_sprite.play("run")

func try_cast_skill() -> void:
	if (current_state == BossState.CHALLENGE || current_state == BossState.CASTING) && can_cast==false:
		return
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < 75 and not is_1_on_cooldown:
		start_casting("water_spell_1")
	elif distance_to_player < 750 and not is_2_on_cooldown:
		start_casting("water_spell_2")

func start_casting(skill_name: String) -> void:
	current_state = BossState.CASTING
	animated_sprite.play("cast")
	
	var spell_direction = sign(animated_sprite.scale.x)  # boss facing which direction/ force 1 or -1
	print("Boss passed direction: ", spell_direction) # debug line
	
	# will ONLY cast skills if in casting state
	if current_state != BossState.CASTING:
		return
	
	match skill_name:
		"water_spell_1":
			is_1_on_cooldown = true
			var blast = water_spell_1.instantiate() # blast object
			
			var offset = Vector2(30, 5)
			blast.global_position = global_position + offset * spell_direction
			blast.scale.x = -spell_direction
			#if spell_direction == 1:
				#blast.global_position = global_position + Vector2(30, 5)
			#else:
				#blast.global_position = global_position + Vector2(-30, 5)
			#blast.get_node("AnimatedSprite2D").scale.x = -(spell_direction)
			#blast.get_node("CollisionPolygon2D").scale.x = -(spell_direction)
			
			get_parent().add_child(blast)
			blast.start_animation()
			timer_1.start(3)
		
		"water_spell_2":
			is_2_on_cooldown = true
			var fireball = water_spell_2.instantiate()  # make the "fireball"
			
			fireball.direction = spell_direction
			print("updated fireball direction: ", fireball.direction) # debug line
			
			fireball.global_position = global_position + Vector2(spell_direction * 10, 5) # offset
			  
			fireball.get_node("AnimatedSprite2D").scale.x = spell_direction
			get_parent().add_child(fireball) 
			fireball.start_animation()

			timer_2.start(5)
	
	await animated_sprite.animation_finished
	current_state = BossState.IDLE

func _on_1_cooldown_finished() -> void:
	is_1_on_cooldown = false

func _on_2_cooldown_finished() -> void:
	is_2_on_cooldown = false

func _on_floor() -> void:
	is_jumping = false

# taking damage logic (copied from player.gd)
func take_damage(amount: int) -> void:
	if current_state == BossState.DEAD:
		return
	for i in range(3):  # damage indicator
		animated_sprite.modulate = Color(1, 0, 0, 1)  
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color(1, 1, 1, 1) 
		await get_tree().create_timer(0.1).timeout
	
	current_health -= amount
	if health_ui:
		health_ui.update_health(current_health)
	print("Boss took ", amount, " damage. Health: ", current_health)

func die() -> void:
	#print("BOSS DEFEATED")
	current_state = BossState.DEAD
	$CollisionShape2D.disabled = true
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	if health_ui:
		health_ui.queue_free()
	emit_signal("boss_died", global_position)
	queue_free()
