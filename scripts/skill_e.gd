extends Area2D

@export var animated_sprite: AnimatedSprite2D 
@export var collision_shape: CollisionShape2D 

var spell_direction: int = 1
var damage: int = 3
var has_dealt_damage: bool = false

func _ready():
	if animated_sprite:
		animated_sprite.visible = false
	collision_shape.disabled = true

func cast(direction: int) -> void:
	spell_direction = direction
	if animated_sprite:
		#print("SKILL E visible")
		animated_sprite.visible = true
		collision_shape.disabled = false
		has_dealt_damage = false # reset flag
		#print("SKILL E playing")
		animated_sprite.play("skill_e")
		
	if spell_direction == 1:
		position = Vector2(90, -50)
	else:
		position = Vector2(-90, -50)
		
	await animated_sprite.animation_finished
	animated_sprite.visible = false
	collision_shape.disabled = true

# handle damage
func _on_body_entered(body: Node2D) -> void:
	if not is_instance_valid(self) or not is_instance_valid(body):
		return
	if body.is_in_group("boss") and !has_dealt_damage:
		var final_damage = get_parent().get_final_damage(damage)  
		body.take_damage(final_damage) 
		has_dealt_damage = true
		#collision_shape.disabled = true # prevent multiple instances of damage
