extends Node2D
class_name BlessingPotion

@export var icon_texture: Texture2D

#blessing potion
var used := false  

func _ready() -> void:
	Global.new_stage_started.connect(_on_new_stage_started)

func _on_new_stage_started() -> void:
	used = false

func use(player: Node) -> bool:
	if used:
		print("Blessing potion already used.")
		return false

	used = true
	if player.has_method("activate_blessing"):
		player.activate_blessing()
		print("Elder Faerie Blessing activated: player will be saved on death!")
		return true
	else:
		print("Elder Faerie Blessing Invalid")
		return false
