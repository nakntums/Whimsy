extends Node2D

class_name Potion

var cooldown := 30.0
var last_used := -999.0

func use(player: Node) -> bool:
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_used < cooldown:
		print("Potion is on cooldown!")
		return false

	last_used = now
	player.current_health = min(player.max_health, player.current_health + 9)
	player.current_mana = min(player.max_mana, player.current_mana + 10)
	
	if player.health_ui:
		player.health_ui.update_hearts(player.current_health)
	if player.mana_ui:
		player.mana_ui.update_mana_text(player.current_mana)
	
	print("Used potion! +9 health, +10 mana")
	return true
