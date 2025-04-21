extends Node2D

@export var spell_circle: AnimatedSprite2D 
@export var laser: Area2D

@onready var laser_attack: AnimatedSprite2D = $Laser/laser_attack
@onready var collision_polygon: CollisionPolygon2D = $Laser/CollisionPolygon2D

var spell_direction: int = 1
var damage: int = 5
var has_dealt_damage: bool = false

func _ready():
	if spell_circle:
		spell_circle.visible = false
	if laser_attack:
		laser_attack.visible = false
	collision_polygon.disabled = true

func cast(direction: int) -> void:
	spell_direction = direction
	has_dealt_damage = false
	
	# positioning first
	spell_circle.position = Vector2(0, -10)
	if spell_direction == -1:
		laser.position = Vector2(-520, 10)
		collision_polygon.position = Vector2(0, 10)
	else:
		laser.position = Vector2(0, 10)
		collision_polygon.position = Vector2(0, 10)
	laser_attack.scale.x = spell_direction
	collision_polygon.scale.x = spell_direction
	
	if spell_circle:
		spell_circle.visible = true
		spell_circle.play("spell_circle")
	if laser_attack:
		collision_polygon.disabled = false
		laser_attack.visible = true
		laser_attack.play("laser_attack")

	await laser_attack.animation_finished
	laser_attack.visible = false
	spell_circle.visible = false
	collision_polygon.disabled = true

func _on_animation_finished() -> void:
	visible = false
	collision_polygon.disabled = true  

# handle damage
func _on_body_entered(body: Node2D) -> void:
	if not is_instance_valid(self) or not is_instance_valid(body) or has_dealt_damage:
		return
	if body.is_in_group("boss"):
		body.take_damage(damage) 
		has_dealt_damage = true
		#collision_polygon.disabled = true
