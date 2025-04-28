extends Node2D
class_name StrengthPotion

@export var icon_texture: Texture2D
@export var strength_multiplier := 2.0 

var is_strength_active := false

func use(player: Node) -> bool:
	player.damage_multiplier = strength_multiplier
	is_strength_active = true
	return true
