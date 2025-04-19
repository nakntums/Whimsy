extends CanvasLayer
class_name GenericDialogue

signal dialogue_finished

@onready var portrait: TextureRect = $Panel/Portrait
@onready var label: Label = $Panel/Label
@onready var advance_timer: Timer = $Panel/AdvanceTimer

var current_dialogue: Array
var auto_advance_seconds := 5.0  

func start_dialogue(json_path: String) -> void:
	if not FileAccess.file_exists(json_path):
		push_error("Dialogue file missing: ", json_path)
		return
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	
	if json == null or not json.has("conversation"):
		push_error("Invalid JSON format in: ", json_path)
		return
	
	current_dialogue = json["conversation"]
	_show_next_line()

func _show_next_line() -> void:
	if current_dialogue.is_empty():
		_end_dialogue()
		return
	
	var line: Dictionary = current_dialogue.pop_front()
	
	# Set portrait if specified
	if line.has("portrait") and ResourceLoader.exists(line["portrait"]):
		portrait.texture = load(line["portrait"])
	
	# Display full text immediately
	label.text = line["text"]
	
	# Set up auto-advance if enabled
	if auto_advance_seconds > 0:
		advance_timer.start(auto_advance_seconds)

func _end_dialogue() -> void:
	dialogue_finished.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		advance_timer.stop()  # Cancel any pending auto-advance
		_show_next_line()

func _on_advance_timer_timeout() -> void:
	_show_next_line()
