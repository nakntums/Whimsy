extends CanvasLayer
class_name ManaUI

@export var current_mana: Label 
@export var max_mana: int = 10
var has_mana_cap: bool = true

func update_mana_text(mana: int):
	if has_mana_cap:
		current_mana.text = "%d / %d" % [mana, max_mana]
	else:
		current_mana.text = "%d" % [mana]

# need to add this to upgrade code later 
#var mana_ui = get_node("/root/Game/ManaUI")
#mana_ui.has_mana_cap = false
