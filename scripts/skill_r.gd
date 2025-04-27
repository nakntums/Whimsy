extends Node2D

@export var spell_circle: AnimatedSprite2D
@export var laser: Area2D

@onready var laser_attack: AnimatedSprite2D = $Laser/laser_attack
@onready var collision_polygon: CollisionPolygon2D = $Laser/CollisionPolygon2D

var spell_direction := 1
var damage := 5
var has_dealt_damage := false
var active := false

func _ready():
	spell_circle.visible = false
	laser_attack.visible = false
	collision_polygon.disabled = true
	laser.monitoring = false
	set_process(false)

func cast(direction: int) -> void:
	spell_direction = direction
	has_dealt_damage = false
	active = true
	
	# set position and 
	spell_circle.position = Vector2(0, -10)
	if spell_direction == -1:
		laser.position = Vector2(-520, 10)
		collision_polygon.position = Vector2(0, 10)
	else:
		laser.position = Vector2(0, 10)
		collision_polygon.position = Vector2(520, 10)
	laser_attack.scale.x = spell_direction
	collision_polygon.scale.x = spell_direction

	# visuals
	spell_circle.visible = true
	spell_circle.play("spell_circle")
	laser_attack.visible = true
	laser_attack.play("laser_attack")

	# hitbox
	collision_polygon.disabled = false
	laser.monitoring = true
	set_process(true)  # start manual checking

	await laser_attack.animation_finished

	# clean up
	spell_circle.visible = false
	laser_attack.visible = false
	collision_polygon.disabled = true
	laser.monitoring = false
	set_process(false)
	active = false

func _process(_delta):
	if active and not has_dealt_damage:
		for body in laser.get_overlapping_bodies():
			if body.is_in_group("boss"):
				var final_damage = get_parent().get_final_damage(damage)  
				body.take_damage(final_damage)
				has_dealt_damage = true
				break  # only deal damage once
