extends CanvasLayer

@onready var slots := [
	$Background/Slot1,
	$Background/Slot2,
	$Background/Slot3
]

var inventory_ref: Inventory = null

func connect_to_inventory(inventory: Inventory):
	inventory_ref = inventory
	inventory_ref.inventory_updated.connect(update_all_slots)
	update_all_slots()

func update_all_slots():
	for i in range(3):
		update_slot(i)

func update_slot(index: int):
	if inventory_ref == null or index >= slots.size():
		return
	var slot = slots[index]
	if inventory_ref.items[index] == null:
		slot.texture = null
		return
	   
	if inventory_ref.items[index] is Potion:
		slot.texture = preload("res://assets/portraits/Refillable_Potion.png")
	elif inventory_ref.items[index] is StrengthPotion:
		slot.texture = preload("res://assets/portraits/Strength_Potion.png")
	elif inventory_ref.items[index] is BlessingPotion:
		slot.texture = preload("res://assets/portraits/Shield_Potion.png")
	
	if inventory_ref.used_states[index]:
		slot.modulate = Color(0.5, 0.5, 0.5, 0.7)  # used gray
	else:
		slot.modulate = Color(1, 1, 1, 1)  # ready normal
	
