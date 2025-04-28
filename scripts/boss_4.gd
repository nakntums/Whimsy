extends CharacterBody2D

signal boss_died(boss_position: Vector2)

enum BossState {
	IDLE,
	DEAD,
	CHALLENGE,
	STILL # for dialogue and vulnerable phase
}

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var player : CharacterBody2D = get_node("/root/Game/Player")

# boss health 
@export var max_health : int = 30
@onready var current_health : int = max_health

# boss healh ui
@export var health_ui_scene: PackedScene
@export var boss_name := "???"
var health_ui: Node

var current_state: BossState = BossState.IDLE
var previous_state: BossState 

func _ready() -> void:
	animated_sprite.play("idle")
	
	if health_ui_scene:
		health_ui = health_ui_scene.instantiate()
		get_node("/root/Game/BossUI").add_child(health_ui)
		health_ui.init_boss(boss_name, max_health)
	
	var typing_challenge = get_node("/root/Game/TypingChallenge")
	if typing_challenge:
		typing_challenge.challenge_started.connect(start_challenge)
		typing_challenge.challenge_ended.connect(end_challenge)
		typing_challenge.typing_completed.connect(_on_typing_result)
	else:
		push_warning("NO TYPING CHALLENGE FOUND")

func _physics_process(delta: float) -> void:

	if current_health <= 0:
		die()
	
	match current_state:
		BossState.IDLE:
			handle_idle()
		BossState.CHALLENGE:
			handle_challenge()
		BossState.STILL:
			handle_still()
		BossState.DEAD:
			return
	
func start_challenge():
	current_state = BossState.CHALLENGE
	print("BOSS HAS ENTERED CHALLENGE STATE")

func end_challenge(success: bool) -> void:
	if success:
		previous_state = current_state
		current_state = BossState.STILL
		print("CHALLENGE SUCCESS: BOSS IS DIZZY!")
		start_blinking_effect(10.0)
		await get_tree().create_timer(10.0).timeout
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

var can_cast := true
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
	animated_sprite.play("idle")
	velocity = Vector2.ZERO

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

func _on_typing_result(success: bool):
	if success:
		print("Boss takes 1 damage from successful typing!")
		take_damage(1)

func die() -> void:
	#print("BOSS DEFEATED")
	current_state = BossState.DEAD
	$CollisionShape2D.disabled = true
	
	var fade_duration = 2.0  
	var timer = 0.0

	while timer < fade_duration:
		var alpha = 1.0 - (timer / fade_duration)  
		animated_sprite.modulate.a = alpha 
		await get_tree().create_timer(0.05).timeout  
		timer += 0.05
	
	
	await animated_sprite.animation_finished
	if health_ui:
		health_ui.queue_free()
	emit_signal("boss_died", global_position)
	queue_free()
