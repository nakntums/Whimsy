extends Camera2D

var player : CharacterBody2D
var threshold : float = 200
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_node("/root/Game/Player")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player.position.x > position.x + threshold:
		position.x = player.position.x - threshold
	elif player.position.x < position.x - threshold:
		position.x = player.position.x + threshold
	position.y = position.y
