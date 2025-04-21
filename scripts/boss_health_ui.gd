extends CanvasLayer
class_name BossHealthUI

@export var boss_name: Label 
# add real health bar if have time. 
@export var health_bar: TextureProgressBar 
@export var health_text: Label 

func _ready():
	pass

func init_boss(name: String, max_health: int):
	boss_name.text = name
	health_bar.max_value = max_health
	health_bar.value = max_health
	update_health_text(max_health)
	show()

func update_health(current_health: int):
	health_bar.value = current_health
	update_health_text(current_health)
	# might add screen shake or something later

func update_health_text(health: int):
	health_text.text = "%d/%d" % [health, health_bar.max_value]
