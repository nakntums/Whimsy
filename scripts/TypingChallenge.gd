extends CanvasLayer

signal typing_completed(success: bool)
signal letter_correct()
signal letter_incorrect()
signal player_damaged(amount: int)

# for boss
signal challenge_started()
signal challenge_ended()
var is_challenge_active := false

@export var word_database: JSON
var word_data: Dictionary
@export var word_spawn_interval: float = 3

var active_words = []
@export var spawn_area_min_ratio: float = 0.4  
@export var spawn_area_max_ratio: float = 0.2 
@export var min_word_spacing: float = 50.0
var occupied_y_positions = [] 
var words_typed_successfully := 0

# adjust later for difficulty
@export var scroll_speeds: Dictionary = {
	"easy": 75,
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
	set_process_input(false)
	if word_database:  # if valid, set equal
		word_data = word_database.data
	else:  # fallback to file loading
		load_word_data()
	
	# checks if spawn timer and word ui is working
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
	if is_challenge_active:
		return
	is_challenge_active = true
	word_difficulty = difficulty
	words_typed_successfully = 0
	show()
	spawn_timer.start()  # begin spawning words
	emit_signal("challenge_started") 

func _on_spawn_timer_timeout():
	var new_word = _get_random_word()
	_spawn_word(new_word)

func _spawn_word(word: String):
	var new_label = word_label_scene.instantiate()
	word_container.add_child(new_label)
	
	# random position, but still in the same area (60%-80% of the screen)
	var y_pos = _get_available_y_position()
	occupied_y_positions.append(y_pos)

	new_label.position = Vector2(
		screen_width,
		y_pos
	)
	
	if active_words.is_empty():
		new_label.modulate = Color(1, 1, 1)  # normal white font color for active wor
	else:
		new_label.modulate = Color(0.7, 0.7, 0.7, 0.5) # non active words greyed out
	
	# Store word data
	active_words.append({
		"label": new_label,
		"word": word,
		"typed": 0,
		"x_pos": new_label.position.x,
		"y_pos": y_pos,
		"mistakes": 0
	})

	_update_word_display(active_words.back())
	
func _get_available_y_position() -> float:
	var viewport_height = get_viewport().get_visible_rect().size.y
	var min_y = viewport_height * spawn_area_min_ratio
	var max_y = viewport_height * spawn_area_max_ratio
	var attempt = 0
	var max_attempts = 10

	while attempt < max_attempts:
		var y_pos = randf_range(min_y, max_y)
		var valid_position = true

		# check against occupied positions
		for occupied_y in occupied_y_positions:
			if abs(y_pos - occupied_y) < min_word_spacing:
				valid_position = false
				break
				
		if valid_position:
			return y_pos
		
		attempt += 1
	
	# fall back 1 is to find position with max spacing
	if occupied_y_positions.size() > 0:
		occupied_y_positions.sort()
		
		var best_gap = 0.0
		var best_y = min_y
		for i in range(occupied_y_positions.size() - 1):
			var gap = occupied_y_positions[i+1] - occupied_y_positions[i]
			if gap > best_gap and gap > min_word_spacing:
				best_gap = gap
				best_y = occupied_y_positions[i] + min_word_spacing
		return clamp(best_y, min_y, max_y)
	
	# fall back 2 is to just make it spawn on base
	return (min_y + max_y) * 0.4

func _process(delta):
	if not visible: return
	
	for word_data in active_words.duplicate(): 
		# word flies from right to left on screen
		word_data.x_pos -= scroll_speeds[word_difficulty] * delta
		word_data.label.position.x = word_data.x_pos
		# if word went off screen, word is gone
		if word_data.x_pos + word_data.label.size.x < 0:
			_remove_word(word_data, false)

func _input(event: InputEvent):
	if not visible: return
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.as_text().to_lower()
		if key.length() == 1 and key in "abcdefghijklmnopqrstuvwxyz0123456789":
			_process_key_input(key)

func _process_key_input(key: String):
	if active_words.is_empty():
		return
	
	var word_data = active_words[0]
	
	if word_data.typed < word_data.word.length():
		# correct
		if key==word_data.word[word_data.typed]:
			word_data.typed += 1
			word_data.mistakes = 0 # reset mistakes on correct input
			_update_word_display(word_data)
			emit_signal("letter_correct")

			if word_data.typed == word_data.word.length():
				words_typed_successfully += 1
				_remove_word(word_data, true)
				if not active_words.is_empty():
					active_words[0].label.modulate = Color(1,1,1)
		# incorrect
		else: 
			word_data.mistakes += 1
			emit_signal("player_damaged", 1)
			emit_signal("letter_incorrect")
			_update_word_display(word_data)


func _update_word_display(word_data):
	var bbcode_text = ""
	for i in range(word_data.word.length()):
		# green letters typed correctly, red letters typed incorrectly, default white letters
		if i < word_data.typed:
			bbcode_text += "[color=green]%s[/color]" % word_data.word[i]
		elif word_data.mistakes > 0 and i == word_data.typed:
			bbcode_text += "[color=red]%s[/color]" % word_data.word[i]
		else:
			bbcode_text += word_data.word[i]
	
	word_data.label.text = bbcode_text
	word_data.label.reset_size() # dynamically update label size

func _remove_word(word_data, success):
	occupied_y_positions.erase(word_data.y_pos)
	emit_signal("typing_completed", success)
	word_data.label.queue_free()
	active_words.erase(word_data)
	
	if not active_words.is_empty():
		active_words[0].label.modulate = Color(1,1,1)

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

func stop_challenge(no_damage: bool = false):
	if not is_challenge_active:
		return
	
	is_challenge_active = false
	spawn_timer.stop()
	hide()

	emit_signal("challenge_ended")
	
	var required_words := _get_required_word_count()
	var performed_well := words_typed_successfully >= required_words
	
	# clear all words - does not damage player if they performed well (passed threshold)
	occupied_y_positions.clear()
	for word_data in active_words.duplicate():
		_remove_word(word_data, no_damage or performed_well)
	

func _get_required_word_count() -> int:
	match word_difficulty:
		"easy":
			return 10
		"medium":
			return 15
		"hard":
			return 20
		"insane":
			return 30
		_:
			return 0  # fallback

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
