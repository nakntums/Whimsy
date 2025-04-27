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
var SPEED = 250.0
const JUMP_VELOCITY = -400.0

# extended running logic
const MOVEMENT_THRESHOLD = 0.3
var time_moving = 0.0
const LOOP_FRAMES = [4, 5, 6]
var loop_frame_index = 0

# player stats
@export var max_health : int = 9
@onready var current_health : int 
@onready var health_ui = get_node("/root/Game/HealthUI")
@export var max_mana : int = 100
@onready var current_mana : int 
@onready var mana_ui = get_node("/root/Game/ManaUI")
@onready var inventory: Inventory = $Inventory

# elder faerie blessing
var has_blessing := false
var blessing_active := false
var blessing_invulnerability_timer := 0.0
var is_invulnerable := false

# components
@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape : CollisionShape2D = $CollisionShape2D

# spells and cooldowns
var can_cast = true
var damage_multiplier: float = 1.0
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

const MANA_COSTS = {
	"flame": 0,
	"heal": 1,
	"lightning": 0,
	"ultimate": 0
}

# combat mode 
var spell_direction = 1
var is_casting = false
var is_q_on_cooldown = false 
var is_w_on_cooldown = false 
var is_e_on_cooldown = false 
var is_r_on_cooldown = false 

var is_damage_buffer_active = false
@onready var damage_buffer_timer: Timer = $DamageBufferTimer

# typing mode 
var is_typing_mode = false
var typed_text = ""
var typing_challenge = CanvasLayer

func _ready() -> void:
	
	# connect game state
	current_health = GameState.player_health if GameState.player_health > 0 else max_health
	current_mana = GameState.player_mana
	load_inventory()
	
	# animation 
	loop_frame_index = 0 # reset frame index on start

	# connect cooldown timers
	timer_q.connect("timeout", Callable(self, "_on_q_cooldown_finished"))
	timer_e.connect("timeout", Callable(self, "_on_e_cooldown_finished"))
	timer_r.connect("timeout", Callable(self, "_on_r_cooldown_finished"))
	heal_cooldown_timer.connect("timeout", Callable(self, "_on_heal_cooldown_finished"))
	damage_buffer_timer.connect("timeout", Callable(self, "_on_damage_buffer_timeout"))
	
	typing_challenge = get_node("/root/Game/TypingChallenge")
	if typing_challenge:
		typing_challenge.typing_completed.connect(_on_typing_result)
		typing_challenge.player_damaged.connect(take_damage)
		# connect letter correct/incorrect later if have time to add audio/visual feedback
	else: 
		push_warning("NO TYPING CHALLENGE FOUND")
	
	if mana_ui:
		mana_ui.update_mana_text(current_mana)

# inventory game state
func load_inventory():
	for path in GameState.inventory_item_paths:
		if path is String:
			var scene = load(path)
			if scene:
				var item = scene.instantiate()
				inventory.add_item(item, path)
		else:
			inventory.add_item(null, "null")
	
func get_inventory() -> Inventory:
	return $Inventory
	
func _physics_process(delta: float) -> void:
	if is_invulnerable:
		blessing_invulnerability_timer -= delta
		if blessing_invulnerability_timer <= 0:
			is_invulnerable = false
			print("Blessing active! Death defied!")
		
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
		
	# casting spells
	if can_cast:
		if Input.is_action_pressed("attack_q") and !is_casting and !is_q_on_cooldown:
			start_casting("flame")
		if Input.is_action_pressed("attack_w") and !is_casting and !is_w_on_cooldown:
			start_casting("heal") 
		if Input.is_action_pressed("attack_e") and !is_casting and !is_e_on_cooldown:
			start_casting("lightning")
		if Input.is_action_pressed("attack_r") and !is_casting and !is_r_on_cooldown:
			start_casting("ultimate") 
	
	# using items
	if Input.is_action_pressed("use_item_1"):
		inventory.use_item(0, self)
	if Input.is_action_pressed("use_item_2"):
		inventory.use_item(1, self)
	if Input.is_action_pressed("use_item_3"):
		inventory.use_item(2, self)
		
	if direction == 0:
		time_moving = 0  # reset timer when player not moving and play dismount animation
		if animated_sprite.animation == "run" and !animated_sprite.is_playing():
			animated_sprite.play("dismount")
	else: 
		time_moving += delta
		
	# Move the sprite based on velocity
	move_and_slide()
	
func fail_sequence() -> void:
	can_cast = false
	velocity.x = 0
	velocity.y = 0

func normalize() -> void:
	can_cast = true

# Combat mode spell casting 
func start_casting(spell_type: String) -> void:
	var cost = MANA_COSTS.get(spell_type, 0)
	if current_mana < cost:
		print("Not enough mana to cast ", spell_type)
		return
	
	current_mana -= cost
	if mana_ui:
		mana_ui.update_mana_text(current_mana)
	
	is_casting = true
	
	match spell_type:
		"flame":
			animated_sprite.play("cast_q")
			flame_spell.cast(animated_sprite.scale.x)
			is_q_on_cooldown = true
			timer_q.start(3.0)
		"heal":
			animated_sprite.play("cast_w")
			heal_cooldown_timer.start(5.0)
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
			timer_r.start(8.0)
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

func get_final_damage(base_damage: int) -> int:
	return int(base_damage * damage_multiplier)

func _on_q_cooldown_finished() -> void:
	is_q_on_cooldown = false
func _on_heal_cooldown_finished() -> void:
	is_w_on_cooldown = false
func _on_e_cooldown_finished() -> void:
	is_e_on_cooldown = false
func _on_r_cooldown_finished() -> void:
	is_r_on_cooldown = false
func _on_damage_buffer_timeout() -> void:
	is_damage_buffer_active = false

# typing logic 
func _input(event: InputEvent) -> void:
	# player presses ctrl and switches btw typing mode/idle mode
	if event.is_action_pressed("toggle_typing"):
		if current_state == PlayerState.TYPING:
			print("LEAVING TYPING MODE")
			set_current_state(PlayerState.IDLE)
			typed_text = ""
			if typing_challenge:
				typing_challenge.set_process_input(false)  # disable typing challenge input
				set_physics_process(true)
				is_casting = false
		else:
			set_current_state(PlayerState.TYPING)
			print("CURRENTLY IN TYPING MODE")
			if typing_challenge:
				typing_challenge.set_process_input(true)  # enable typing challenge input
	
	# only process typing inputs if in typing mode - debugging
	if current_state != PlayerState.TYPING:
		return
	
	# feedback for debugging
	#if current_state == PlayerState.TYPING:
		#if event is InputEventKey and event.pressed and not event.echo:
			#var key = event.as_text()
			#if key.length() == 1:  # only capture single character keys
				#typed_text += key
				#print("Typed text: ", typed_text) 
				
				

func set_current_state(new_state: PlayerState):
	print("State change: %s -> %s" % [PlayerState.keys()[current_state], PlayerState.keys()[new_state]])
	current_state = new_state

func _on_typing_result(success: bool):
	if not success:
		print("player took 1 damage from failed typing")
		take_damage(1)
	if success:
		current_mana = min(current_mana+1, max_mana)
		if mana_ui:
			mana_ui.update_mana_text(current_mana)

# taking damage logic 
func take_damage(amount: int) -> void:
	
	# elder faerie blessing
	if is_invulnerable:
		print("DAMAGE IGNORED: PLAYER IS INVULNERABLE")
		return
	# i-frames (damage buffer)
	if is_damage_buffer_active:
		print("DAMAGE IGNORED: PLAYER IN I-FRAME or INVULNERABLE")
		return
		
	is_damage_buffer_active = true
	damage_buffer_timer.start()
	
	current_health -= amount
	#debug line
	print("Player took ", amount, " damage. Health: ", current_health)
	if health_ui:
		health_ui.play_damage_effect()
		health_ui.update_hearts(current_health)
		
	for i in range(3):  # damage indicator
		animated_sprite.modulate = Color(1, 0, 0, 1)  
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color(1, 1, 1, 1) 
		await get_tree().create_timer(0.1).timeout

# guardian angel effect (elder faerie blessing)
func activate_blessing():
	has_blessing = true
	print("Elder Faerie prevented you from death. React quickly!")

# retain hp/mp/items between levels
func save_state():
	GameState.player_health = current_health
	GameState.player_mana = current_mana
	GameState.inventory_item_paths = inventory.get_items()

signal died
func die() -> void:
	# don't die if have elder faerie blessing
	if has_blessing:
		trigger_blessing()
		return
	# prevents further input processing
	set_physics_process(false)
	set_process_input(false)
	
	if current_state == PlayerState.TYPING:
		set_current_state(PlayerState.IDLE)
		if typing_challenge:
			typing_challenge.stop_challenge()
	
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	emit_signal("died")
	
# one time trigger 
func trigger_blessing():
	current_health = 1
	if health_ui:
		health_ui.update_hearts(current_health)
	is_invulnerable = true
	blessing_invulnerability_timer = 5.0  # 5 seconds of invulnerability
	has_blessing = false  # blessing is used up
