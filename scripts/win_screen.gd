extends Node2D

@onready var wpm_label = $Control/WPM
@onready var accuracy_label = $Control/Accuracy
@onready var main_menu_button = $Control/Button2

@export var main_menu_scene: PackedScene

func _ready():
	var wpm = GameState.get_average_wpm()
	var accuracy = GameState.get_accuracy()
	wpm_label.text = "WPM: %.2f" % wpm
	accuracy_label.text = "Accuracy: %.2f%%" % accuracy
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _on_main_menu_pressed():
	GameState.reset()
	get_tree().change_scene_to_packed(main_menu_scene)
