extends Node2D
class_name Inventory

# inventory like a hotbar, key 1-9 to use items
const MAX_SLOTS := 9
var items := [null, null, null, null, null, null, null, null, null] 

func add_item(item: Node):
	for i in range(MAX_SLOTS):
		if items[i] == null:
			items[i] = item
			print("Added item to slot", i + 1)
			return true
	print("Inventory full!")
	return false
	
func remove_item(index: int) -> void:
	if index >= 0 and index < MAX_SLOTS:
		items[index] = null
	
func use_item(index: int, user: Node) -> void:
	if index >= 0 and index < MAX_SLOTS and items[index]:
		if items[index].has_method("use"):
			var success = items[index].use(user)
			# debug line
			#if success:
				#print("Used item in slot", index + 1)
			#else:
				#print("Item in slot", index + 1, "is prob on cd")
				
# for game state management
func get_items() -> Array:
	var paths := []
	for item in items:
		if item:
			paths.append(item.get_scene().resource_path)
		else:
			paths.append(null)
	return paths
