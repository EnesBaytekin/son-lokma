extends Node2D
## Son Lokma — a plate with three food slots.
##
## Keys 1 / 2 / 3 take a bite from the left / middle / right slot.
## When a slot's food runs out, a new random food is spawned there.

const FOOD_SCENES: Array[PackedScene] = [
	preload("res://scenes/foods/sarma.tscn"),
	preload("res://scenes/foods/kisir.tscn"),
	preload("res://scenes/foods/kek.tscn"),
]

@onready var _slots: Array[Marker2D] = [
	$Slots/SlotLeft,
	$Slots/SlotMiddle,
	$Slots/SlotRight,
]

var _foods: Array[Food] = [null, null, null]


func _ready() -> void:
	randomize()
	for i in _slots.size():
		_spawn_food(i)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var slot := -1
	match key_event.keycode:
		KEY_1, KEY_KP_1:
			slot = 0
		KEY_2, KEY_KP_2:
			slot = 1
		KEY_3, KEY_KP_3:
			slot = 2

	if slot >= 0 and _foods[slot] != null:
		_foods[slot].take_bite()


func _spawn_food(slot_index: int) -> void:
	var scene: PackedScene = FOOD_SCENES[randi() % FOOD_SCENES.size()]
	var food: Food = scene.instantiate()
	_slots[slot_index].add_child(food)
	food.position = Vector2.ZERO
	food.emptied.connect(_on_food_emptied.bind(slot_index))
	_foods[slot_index] = food


func _on_food_emptied(_food: Food, slot_index: int) -> void:
	if _foods[slot_index] != null:
		_foods[slot_index].queue_free()
		_foods[slot_index] = null
	_spawn_food(slot_index)
