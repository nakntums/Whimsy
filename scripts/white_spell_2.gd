extends Area2D

@export var animated_sprite: AnimatedSprite2D
@export var collision_shape: CollisionShape2D

@export var speed: float = 300.0
@export var max_range: float = 400.0

@export var damage: int = 2

var direction : float = 2
var start_position: Vector2
var can_deal_damage = true

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
	if body.is_in_group("player") and can_deal_damage:
		body.take_damage(damage)
		can_deal_damage = false

func start_animation() -> void:
	if animated_sprite:
		#print("animation becoming visible")
		animated_sprite.visible = true
		#print("animation playing")
		animated_sprite.play("white_spell_2")
