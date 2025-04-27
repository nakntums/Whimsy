extends Node

var strength_potion_duration := 10.0
var strength_multiplier := 2.0  
var is_strength_active := false
var strength_potion_timer := 0.0
var player_reference: Node = null

func use(player: Node) -> void:
	if is_strength_active:
		print("Strength potion is already active!")
		return

	player.damage_multiplier = strength_multiplier
	is_strength_active = true
	strength_potion_timer = strength_potion_duration
	player_reference = player 
	print("Strength potion activated! Double damage for ", strength_potion_duration, " seconds.")

func _process(delta: float) -> void:
	if is_strength_active:
		strength_potion_timer -= delta
		if strength_potion_timer <= 0:
			remove_strength_potion_effect(player_reference)

func remove_strength_potion_effect(player: Node) -> void:
	if not is_strength_active:
		return

	player.damage_multiplier = 1.0  
	is_strength_active = false
	strength_potion_timer = 0.0
	print("Strength potion effect has ended!")
