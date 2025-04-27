extends CanvasLayer

#@export var max_hearts := 9
@export var heart_texture : Texture
@export var heart_size := Vector2(36, 36)  

@onready var hearts_container = $Control/HeartsContainer

func _ready():
	hearts_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hearts_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	await get_tree().process_frame
	initialize_hearts()

func initialize_hearts():
	if not hearts_container:
		print("NO HEARTSCONTAINER FOUND")
		return
	# clear existing hearts
	for child in hearts_container.get_children():
		child.queue_free()

	# make new hearts as needed
	for i in range(GameState.player_health):
		var heart = TextureRect.new()
		heart.name = "Heart_%d" % (i+1)
		heart.texture = heart_texture
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = heart_size
		
		heart.modulate.a = 0
		hearts_container.add_child(heart)

		var tween = create_tween()
		tween.tween_property(heart, "modulate:a", 1.0, 0.2).set_delay(i * 0.05)

func update_hearts(current_health: int):
	if not hearts_container:
		print("NO HEARTSCONTAINER FOUND")
		return
	
	var hearts = hearts_container.get_children()
	
	for i in range(hearts.size()):
		var heart = hearts[i]
		var should_be_visible = i < current_health
		if heart.visible == should_be_visible:
			continue
		if should_be_visible:
			# fade in when healed
			heart.visible = true
			var tween = create_tween()
			tween.tween_property(heart, "modulate:a", 1.0, 0.3)
		else:
			# fade out when losing health
			var tween = create_tween()
			tween.tween_property(heart, "modulate:a", 0.0, 0.2)
			tween.tween_callback(heart.set.bind("visible", false))
	
func play_damage_effect():
	if not hearts_container:
		print("NO HEARTSCONTAINER FOUND")
		return
		
	for heart in hearts_container.get_children():
		if heart.visible:
			var tween = create_tween().set_parallel(true)
			tween.tween_property(heart, "position:x", heart.position.x + 4, 0.1)
			tween.tween_property(heart, "modulate", Color.RED, 0.1)
			tween.chain().tween_property(heart, "position:x", heart.position.x, 0.1)
			tween.tween_property(heart, "modulate", Color.WHITE, 0.1)
