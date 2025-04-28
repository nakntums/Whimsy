extends Node2D
class_name BlessingPotion

@export var icon_texture: Texture2D

#blessing potion
func use(player: Node) -> bool:
	if player.has_method("activate_blessing"):
		player.activate_blessing()
		print("Elder Faerie Blessing Active")
		return true
	else:
		print("Elder Faerie Blessing Invalid")
		return false
