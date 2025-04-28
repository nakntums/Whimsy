extends Node

# player's stats and belongings need to be retained throughout levels
var player_health: int = 9
var player_mana: int = 0
var inventory_item_paths: Array = []

# report
var total_words_typed: int = 0
var total_typing_time: float = 0.0
var total_mistakes: int = 0

func record_challenge(words_typed: int, typing_time: float, mistakes: int):
	total_words_typed += words_typed
	total_typing_time += typing_time
	total_mistakes += mistakes
	
func get_average_wpm() -> float:
	if total_typing_time > 0:
		return (total_words_typed / (total_typing_time / 60.0))
	else:
		return 0.0

func get_accuracy() -> float:
	if total_words_typed > 0:
		return ((total_words_typed - total_mistakes) / total_words_typed) * 100.0
	else:
		return 100.0

func reset():
	player_health = 9
	player_mana = 0
	inventory_item_paths.clear()
	total_words_typed = 0
	total_typing_time = 0.0
	total_mistakes = 0
