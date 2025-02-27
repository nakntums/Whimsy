extends CharacterBody2D

enum BossState {
	IDLE,
	CHASING,
	CASTING
}

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var player : CharacterBody2D = get_node("/root/Game/Player")
@onready var water_spell_1 : Area2D = $water_spell_1
@onready var water_spell_2 : Area2D = $water_spell_2
@onready var timer_1 : Timer = $WaterSpell1Timer
@onready var timer_2 : Timer = $WaterSpell2Timer

const SPEED = 150.0  
const CHASE_RANGE = 1500.0 
const STOP_CHASE_RANGE = 100.0  
const JUMP_VELOCITY = -400.0  
const GRAVITY = 1200.0  
const SKILL_DELAY = 3.0

var current_state: BossState = BossState.IDLE
var is_jumping = false

var is_1_on_cooldown = false
var is_2_on_cooldown = false


func _ready() -> void:
	animated_sprite.play("idle")
	water_spell_1.visible = false
	water_spell_2.visible = false
	#water_spell_1.position = Vector2(-30, 5)
	water_spell_2.position = Vector2(60, 5)
	timer_1.connect("timeout", Callable(self, "_on_1_cooldown_finished"))
	timer_2.connect("timeout", Callable(self, "_on_2_cooldown_finished"))

func _physics_process(delta: float) -> void:
	match current_state:
		BossState.IDLE:
			handle_idle()
		BossState.CHASING:
			handle_chasing(delta)
		BossState.CASTING:
			handle_casting(delta)
	
	if current_state != BossState.CASTING:
		try_cast_skill()

func handle_idle() -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	if not player.is_on_floor() and distance_to_player < STOP_CHASE_RANGE:
		animated_sprite.play("idle")
		velocity = Vector2.ZERO
		return
	if distance_to_player < CHASE_RANGE:
		current_state = BossState.CHASING
	else:
		animated_sprite.play("idle")
		velocity = Vector2.ZERO

func handle_chasing(delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= STOP_CHASE_RANGE:
		current_state = BossState.IDLE
		return
	
	var direction_to_player = (player.position - position).normalized()
	velocity.x = direction_to_player.x * SPEED
	
	if direction_to_player.x > 0:
		animated_sprite.scale.x = 1 
	elif direction_to_player.x < 0:
		animated_sprite.scale.x = -1  
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	if is_on_floor() and not is_jumping and position.y > player.position.y + 50:
		velocity.y = JUMP_VELOCITY
		is_jumping = true
	
	animated_sprite.play("run")
	move_and_slide()

func handle_casting(delta: float) -> void:
	velocity = Vector2.ZERO
	animated_sprite.play("cast")
	await animated_sprite.animation_finished
	
	current_state = BossState.IDLE
	animated_sprite.play("idle")

func try_cast_skill() -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < 100 and not is_1_on_cooldown:
		start_casting("water_spell_1")
	elif distance_to_player < 150 and not is_2_on_cooldown:
		start_casting("water_spell_2")

func start_casting(skill_name: String) -> void:
	current_state = BossState.CASTING
	var spell_direction = animated_sprite.scale.x

	match skill_name:
		"water_spell_1":
			if spell_direction==1:
				water_spell_1.position = Vector2(30, 5)
			else:
				water_spell_1.position = Vector2(-30, 5)
			water_spell_1.get_node("AnimatedSprite2D").scale.x = -(spell_direction)
			is_1_on_cooldown = true
			water_spell_1.visible = true
			water_spell_1.get_node("AnimatedSprite2D").play("water_spell_1")
			timer_1.start(5)
			is_1_on_cooldown = true
		
		"water_spell_2":
			is_2_on_cooldown = true
			water_spell_2.visible = true
			water_spell_2.get_node("AnimatedSprite2D").play("water_spell_2")
			timer_2.start(7)
			is_2_on_cooldown = true
	
	await animated_sprite.animation_finished

	match skill_name:
		"water_spell_1":
			water_spell_1.visible = false
		"water_spell_2":
			water_spell_2.visible = false
	current_state = BossState.IDLE


func _on_1_cooldown_finished() -> void:
	is_1_on_cooldown = false

func _on_2_cooldown_finished() -> void:
	is_2_on_cooldown = false

func _on_floor() -> void:
	is_jumping = false
