extends Node

# player's stats and belongings need to be retained throughout levels
var player_health: int = 9
var player_mana: int = 0
var inventory_item_paths: Array = []

func reset():
	player_health = 9
	player_mana = 0
	inventory_item_paths.clear()
