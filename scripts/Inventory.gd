extends Node2D
class_name Inventory
signal inventory_updated

# inventory like a hotbar, key 1-3 to use items
const MAX_SLOTS := 3
var items := [null, null, null]
var item_paths := [null, null, null] 
var used_states := [false, false, false]
@onready var inventory_ui = $InventoryUI 

func _ready():
	if inventory_ui == null:
		inventory_ui = get_node_or_null("../InventoryUI")
	if inventory_ui:
		inventory_ui.connect_items(items)

func add_item(item: Node, scene_path: String) -> int:
	for i in range(MAX_SLOTS):
		if items[i] == null:
			items[i] = item
			item_paths[i] = scene_path
			if inventory_ui:
				inventory_ui.update_slot(i)
				print("Added item to slot", i + 1)
			return i
			
	print("Inventory full!")
	return -1
	
func remove_item(index: int) -> void:
	if index >= 0 and index < MAX_SLOTS:
		items[index] = null
		item_paths[index] = null
		used_states[index] = false
		if inventory_ui:
			inventory_ui.update_slot(index)
	
func use_item(index: int, user: Node) -> bool:
	if index < 0 or index >= MAX_SLOTS or items[index] == null:
		return false
	if used_states[index]:
		return false
	# post-use item logic
	var success = items[index].use(user)
	if success:
		used_states[index] = true
		emit_signal("inventory_updated")
		return true 
	return false
	
# for game state management
func get_items() -> Array:
	return item_paths
