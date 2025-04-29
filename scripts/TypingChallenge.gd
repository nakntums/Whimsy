extends CanvasLayer

signal typing_completed(success: bool)
signal letter_correct()
signal letter_incorrect()
signal player_damaged(amount: int)

# for boss
signal challenge_started()
signal challenge_ended(success: bool, words_typed: int, time_taken: float, mistakes: int)
var is_challenge_active := false

# for report
var challenge_start_time:= 0
var typing_start_time : float = 0.0
var typing_end_time : float = 0.0

@export var word_database: JSON
var word_data: Dictionary

var active_words = []
@export var spawn_area_min_ratio: float = 0.4  
@export var spawn_area_max_ratio: float = 0.2 
@export var min_word_spacing: float = 50.0
var occupied_y_positions = [] 
var words_typed_successfully := 0

# enough words need to spawn to satisfy the wpm
@export var word_spawn_interval: Dictionary = {
	"easy": 2.0,     # 30 WPM (15 words in 30s)
	"medium": 1.5,    # 40 WPM (20 words in 30s)
	"hard": 1.5,      # 50 WPM (20 words in 30s)
	"insane": 1.5     # 60 WPM (40 words in 60s)
}
# scroll speeds ensure player gets on with it lol 
@export var scroll_speeds: Dictionary = {
	"easy": 40, # 30 wpm
	"medium": 45, # 40 wpm
	"hard": 60, # 50 wpm
	"insane": 75 # 60 wpm
}
# speed increases urge players and train their muscle memory
@export var max_scroll_speeds: Dictionary = {
	"easy": 50, # 1.66x
	"medium": 70, # 1.55x
	"hard": 90, # 1.50x
	"insane": 100 # 1.35x
}

var current_word: String = ""
var typed_letters: int = 0
var challenge_elapsed_time := 0.0
var challenge_duration := 30.0  # seconds

#default easy
var word_difficulty: String = "easy"
var scroll_position: float = 0.0

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
		
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	#spawn_timer.start()

func start_challenge(difficulty: String):
	if is_challenge_active:
		return
	is_challenge_active = true
	challenge_elapsed_time = 0.0
	challenge_start_time = Time.get_ticks_msec()
	typing_start_time = Time.get_ticks_msec() / 1000.0
	word_difficulty = difficulty
	words_typed_successfully = 0
	show()
	spawn_timer.wait_time = word_spawn_interval[difficulty]
	spawn_timer.start()  # begin spawning words
	emit_signal("challenge_started") 

func on_last_word_spawned():
	typing_end_time = Time.get_ticks_msec() / 1000.0

func calculate_wpm(words_typed: int) -> float:
	var effective_typing_time = typing_end_time - typing_start_time
	if effective_typing_time <= 0:
		return 0.0
	return (words_typed / effective_typing_time) * 60.0

func _on_spawn_timer_timeout():
	var new_word = _get_random_word()
	_spawn_word(new_word)

func _spawn_word(word: String):
	var new_label = word_label_scene.instantiate()
	word_container.add_child(new_label)
	var word_width = new_label.get_minimum_size().x  

	# random position, but still in the same area (60%-80% of the screen)
	var y_pos = _get_available_y_position(word_width)
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
	
func _get_available_y_position(word_width: float) -> float:
	var viewport_height = get_viewport().get_visible_rect().size.y
	var min_y = viewport_height * spawn_area_min_ratio
	var max_y = viewport_height * spawn_area_max_ratio
	var attempt = 0
	var max_attempts = 10

	while attempt < max_attempts:
		var y_pos = randf_range(min_y, max_y)
		var valid_position = true

		for word_data in active_words:
			var existing_y = word_data.y_pos
			var existing_width = word_data.label.size.x
			var vertical_distance = abs(y_pos - existing_y)

			# Horizontal overlap check — both words are moving from right to left
			# If they’re too close vertically, we assume possible overlap
			if vertical_distance < min_word_spacing:
				valid_position = false
				break

		if valid_position:
			return y_pos

		attempt += 1

	return (min_y + max_y) * 0.4


func _process(delta):
	if not visible: return
	
	# linear speed increase, but curved speed for last bit of rush
	if is_challenge_active:
		challenge_elapsed_time += delta
		var raw_progress = clamp(challenge_elapsed_time / challenge_duration, 0, 1)
		var curved_progress = raw_progress * 0.7 + (raw_progress * raw_progress) * 0.3
		# 70% linear, 30% quadratic split

		var base_speed = scroll_speeds[word_difficulty]
		var max_speed = max_scroll_speeds[word_difficulty]
		var current_speed = lerp(base_speed, max_speed, curved_progress)

		for word_data in active_words.duplicate():
			word_data.x_pos -= current_speed * delta
			word_data.label.position.x = word_data.x_pos

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
			GameState.total_mistakes += 1
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
	
	var typing_duration_sec = (Time.get_ticks_msec() - challenge_start_time) / 1000.0
	GameState.total_words_typed += words_typed_successfully
	GameState.total_typing_time += typing_duration_sec
	
	var required_words := _get_required_word_count()
	var performed_well := words_typed_successfully >= required_words
	
	# clear all words - does not damage player if they performed well (passed threshold)
	occupied_y_positions.clear()
	var failed_word_count := 0
	
	for word_data in active_words.duplicate():
		var was_success := no_damage or performed_well
		if not was_success:
			failed_word_count += 1
		_remove_word(word_data, was_success)
		
	if not performed_well and failed_word_count > 0:
		emit_signal("player_damaged", failed_word_count)
		
	emit_signal("challenge_ended", performed_well)

# player must type at least 50% of max number of words that'll spawn to perform well
# and not take damage when all the words are cleared
func _get_required_word_count() -> int:
	match word_difficulty:
		"easy":
			return 8
		"medium":
			return 10
		"hard":
			return 13
		"insane":
			return 20
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
