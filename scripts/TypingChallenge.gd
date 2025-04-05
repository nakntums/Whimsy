extends CanvasLayer

signal typing_completed(success: bool)
signal letter_correct()
signal letter_incorrect()

@export var word_database: JSON
var word_data: Dictionary
@export var word_spawn_interval: float = 3

var active_words = [] # tracks {label, word, typed, x_pos}
var occupied_y_positions = []
var typing_mode_active := false

# adjust later for difficulty
@export var scroll_speeds: Dictionary = {
	"easy": 50,
	"medium": 100,
	"hard": 150,
	"insane": 200
}

var current_word: String = ""
var typed_letters: int = 0

#default easy
var word_difficulty: String = "easy"
var scroll_position: float = 0.0
var word_width: float = 0.0

@onready var word_container = $Control/WordContainer
@onready var word_label_scene = preload("res://scenes/word_label.tscn")
@onready var spawn_timer = $Control/SpawnTimer
@onready var screen_width: float = get_viewport().get_visible_rect().size.x

func _ready():
	if word_database:  # if valid, set equal
		word_data = word_database.data
	else:  # fallback to file loading
		load_word_data()
	
	# checks if spawn timer is working
	if not spawn_timer:
		push_error("SpawnTimer not found! Check scene tree")
		return

	if not word_container:
		push_error("WordContainer not found! Check scene tree")
		return
		
	spawn_timer.wait_time = word_spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func start_challenge(difficulty: String):
	word_difficulty = difficulty
	show()
	spawn_timer.start()  # begin spawning words

func _on_spawn_timer_timeout():
	var new_word = _get_random_word()
	_spawn_word(new_word)

func _spawn_word(word: String):
	var new_label = word_label_scene.instantiate()
	word_container.add_child(new_label)
	
	# Calculate non-overlapping y position
	var y_pos = _get_available_y_position()
	occupied_y_positions.append(y_pos)

	new_label.position = Vector2(
		screen_width,
		y_pos
	)
	
	# Store word data
	active_words.append({
		"label": new_label,
		"word": word,
		"typed": 0,
		"x_pos": new_label.position.x,
		"y_pos": y_pos
	})

	_update_word_display(active_words.back())
	
func _get_available_y_position() -> float:
	var viewport_height = get_viewport().get_visible_rect().size.y
	var attempt = 0
	var max_attempts = 10

	while attempt < max_attempts:
		var y_pos = randf_range(50, viewport_height - 50)
		var valid_position = true
		
		# check against occupied positions
		for occupied_y in occupied_y_positions:
			if abs(y_pos - occupied_y) < 50:  # Minimum 50px spacing
				valid_position = false
				break
				
		if valid_position:
			return y_pos
		
		attempt+=1
	# fallback if can't find perfect position
	return randf_range(50, viewport_height - 50)

func _process(delta):
	if not visible: return
	
	for word_data in active_words.duplicate(): # Use duplicate to safely modify array while iterating
		# Move word left
		word_data.x_pos -= scroll_speeds[word_difficulty] * delta
		word_data.label.position.x = word_data.x_pos
		# Check if word went off-screen
		if word_data.x_pos + word_data.label.size.x < 0:
			_remove_word(word_data, false)

func _input(event: InputEvent):
	if not visible: return
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.as_text().to_lower()
		if key.length() == 1 and key in "abcdefghijklmnopqrstuvwxyz0123456789":
			_process_key_input(key)

func _process_key_input(key: String):
	var any_correct = false
	
	for word_data in active_words:
		if word_data.typed < word_data.word.length() and key == word_data.word[word_data.typed]:
			word_data.typed += 1
			_update_word_display(word_data)
			any_correct = true

			if word_data.typed == word_data.word.length():
				_remove_word(word_data, true)
			break
	
	emit_signal("letter_correct" if any_correct else "letter_incorrect")

func _update_word_display(word_data):
	var bbcode_text = ""
	for i in range(word_data.word.length()):
		if i < word_data.typed:
			bbcode_text += "[color=green]%s[/color]" % word_data.word[i]
		else:
			bbcode_text += word_data.word[i]
	
	word_data.label.text = bbcode_text
	word_data.label.reset_size() # dynamically update label size

func _remove_word(word_data, success):
	occupied_y_positions.erase(word_data.y_pos)
	emit_signal("typing_completed", success)
	word_data.label.queue_free()
	active_words.erase(word_data)

func _get_random_word() -> String:
	# check if difficulty is available
	if not word_data.has(word_difficulty):
		push_warning("Difficulty %s not found in word data" % word_difficulty)
		return "default"
	# check if there are words available
	if word_data[word_difficulty].is_empty():
		push_error("No words found for difficulty %s" % word_difficulty)
		return "default"
	
	# picks random word
	# difficulty adjuster recommendation : append numbers and symbols in harder difficulties
	return word_data[word_difficulty].pick_random()  

func stop_challenge():
	spawn_timer.stop()
	hide()
	occupied_y_positions.clear()
	# clear
	for word_data in active_words.duplicate():
		_remove_word(word_data, false)

# fail case
func load_word_data():
	var file = FileAccess.open("res://data/words.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			word_data = parsed
		else:
			push_error("Invalid JSON structure")
			_setup_default_words()
	else:
		push_error("Failed to load words.json")
		_setup_default_words()

func _setup_default_words():
	word_data = {
		"easy": ["default"],
		"medium": ["default"],
		"hard": ["default"],
		"insane": ["default"]
	}
