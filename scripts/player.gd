extends CharacterBody2D

var direction = 0
const SPEED = 200.0
const JUMP_VELOCITY = -400.0

# extended running
const MOVEMENT_THRESHOLD = 0.3
var time_moving = 0.0
const LOOP_FRAMES = [4, 5, 6]
var loop_frame_index = 0

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape : CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	loop_frame_index = 0 # reset frame index on start
	pass

func _physics_process(delta: float) -> void:
	
	#debugging
	#print("Physics process running")
	#print("Is on floor: ", is_on_floor())
	#print("Is on wall: ", is_on_wall())
	#print("Player position in main scene: ", position)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += ProjectSettings.get("physics/2d/default_gravity") * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if direction ==0:
		time_moving= 0 # reset timer when player not moving and play dismount animation
		if animated_sprite.animation == "run" and !animated_sprite.is_playing():
			animated_sprite.play("dismount")

	else: 
		time_moving +=delta
	
	# Handle horizontal movement manually
	if Input.is_action_pressed("left"):
		direction = -1
	elif Input.is_action_pressed("right"):
		direction = 1
	else:
		direction = 0

	velocity.x = direction * SPEED
	
	# handle idle and run animations
	if direction == 0:
		if animated_sprite.animation == "dismount" and animated_sprite.frame == 3:
			animated_sprite.play("idle")  
	elif time_moving>=MOVEMENT_THRESHOLD and direction !=0:
		#animated_sprite.play("run")
		loop_frame_index = int(time_moving/0.1)% LOOP_FRAMES.size()
		animated_sprite.frame = LOOP_FRAMES[loop_frame_index]
	else:
		animated_sprite.play("run")  # brief running
		
	if direction == -1:
		animated_sprite.scale.x = -1
	elif direction ==1:
		animated_sprite.scale.x = 1

	# Move the sprite based on velocity
	move_and_slide()
