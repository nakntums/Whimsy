extends Area2D

@export var animated_sprite: AnimatedSprite2D
@export var collision_shape: CollisionPolygon2D

@export var damage: int = 1
@export var duration: float = 0.75

var can_deal_damage: bool = true

func _ready():
	start_duration_timer()

#func _process(delta):
	#if not is_instance_valid(self):
		#return

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(self) or not is_instance_valid(body):
		return
	if body.is_in_group("player") and can_deal_damage:
		body.take_damage(damage)
		can_deal_damage = false # prevents multiple instances of damage in one hit
		await get_tree().create_timer(.5).timeout
		can_deal_damage = true

func start_animation() -> void:
	if animated_sprite:
		#print("WATER BLAST visible")
		animated_sprite.visible = true
		#print("WATER BLAST playing")
		animated_sprite.play("water_spell_1")

func start_duration_timer() -> void:
	# make spell visible for its entire animation duration
	await get_tree().create_timer(duration).timeout
	queue_free()
		
