extends Area2D

@export var animated_sprite: AnimatedSprite2D
@export var collision_shape: CollisionShape2D

@export var speed: float = 200.0
@export var max_range: float = 200.0

@export var damage: int = 1

var direction : float = 1
var start_position: Vector2

func _ready():
	start_position = global_position

func _process(delta):
	if not is_instance_valid(self):
		return
	
	position.x += direction * speed * delta
	if global_position.distance_to(start_position) >= max_range:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(self):
		return
	if body.is_in_group("player"):
		body.take_damage(damage)
		queue_free()

func start_animation() -> void:
	if animated_sprite:
		print("animation becoming visible")
		animated_sprite.visible = true
		print("animation playing")
		animated_sprite.play("water_spell_2")
