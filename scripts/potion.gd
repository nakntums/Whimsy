extends Node2D

class_name Potion

# bottomless potion
@export var icon_texture: Texture2D

func use(player: Node) -> bool:
	player.current_health = min(player.max_health, player.current_health + 3)
	player.current_mana = min(player.max_mana, player.current_mana + 5)
	
	if player.health_ui:
		player.health_ui.update_hearts(player.current_health)
		print(player.current_health)
	if player.mana_ui:
		player.mana_ui.update_mana_text(player.current_mana)
	
	print("Used potion! +3 health, +5 mana")
	return true
