extends CanvasLayer
class_name GenericDialogue

signal dialogue_finished

@onready var portrait: TextureRect = $Panel/Portrait
@onready var label: Label = $Panel/Label
@onready var timer: Timer = $Panel/Timer

var current_dialogue: Array
var current_text := ""
var char_index := 0
var is_typing := false

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
	set_process_input(true)  # Enable input processing
	_show_next_line()

func _show_next_line() -> void:
	if current_dialogue.is_empty():
		_end_dialogue()
		return
	
	var line: Dictionary = current_dialogue.pop_front() 
	
	# Set portrait
	if line.has("portrait") and ResourceLoader.exists(line["portrait"]):
		portrait.texture = load(line["portrait"])
	
	# Start typing effect immediately
	current_text = line["text"]
	label.text = ""
	char_index = 0
	is_typing = true
	timer.wait_time = line.get("speed", 0.05) 
	timer.start()

func _on_timer_timeout() -> void:
	if char_index < current_text.length():
		label.text += current_text[char_index]
		char_index += 1
	else:
		is_typing = false  # Mark line as complete

func _end_dialogue() -> void:
	set_process_input(false)  # Disable input processing
	dialogue_finished.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if is_typing:
			# Skip typing animation if still typing
			timer.stop()
			label.text = current_text
			is_typing = false
		else:
			# Only advance to next line when current line is complete
			_show_next_line()
