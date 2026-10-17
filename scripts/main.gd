extends Node2D
## Son Lokma — a plate with three food slots and a fork.
##
## Keys 1 / 2 / 3 pick a slot: the fork flies there, takes a bite, and carries
## it off-screen. During the carry, SPACE keeps the fork from trembling/spilling.
## Only one bite can be in progress at a time.

const FOOD_SCENES: Array[PackedScene] = [
	preload("res://scenes/foods/sarma.tscn"),
	preload("res://scenes/foods/kisir.tscn"),
	preload("res://scenes/foods/kek.tscn"),
]

const CRUMB_SCENE: PackedScene = preload("res://scenes/crumb.tscn")
const TABLE_Y := 1020.0

@onready var _slots: Array[Marker2D] = [
	$Slots/SlotLeft,
	$Slots/SlotMiddle,
	$Slots/SlotRight,
]
@onready var _fork: Fork = $Fork
@onready var _crumbs: Node2D = $Crumbs

var _foods: Array[Food] = [null, null, null]
var _busy := false


func _ready() -> void:
	randomize()
	_fork.action_finished.connect(_on_fork_finished)
	_fork.spilled.connect(_on_spilled)
	for i in _slots.size():
		_spawn_food(i)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_R:
		_restart()
		return

	var slot := -1
	match key_event.keycode:
		KEY_1, KEY_KP_1:
			slot = 0
		KEY_2, KEY_KP_2:
			slot = 1
		KEY_3, KEY_KP_3:
			slot = 2

	if slot >= 0:
		_select_slot(slot)


func _select_slot(slot_index: int) -> void:
	if _busy:
		return
	var food: Food = _foods[slot_index]
	if food == null:
		return
	_busy = true
	_fork.start_action(food, _slots[slot_index].global_position)


func _on_fork_finished() -> void:
	_busy = false


func _on_spilled(world_pos: Vector2, color: Color) -> void:
	var crumb: Crumb = CRUMB_SCENE.instantiate()
	_crumbs.add_child(crumb)
	crumb.global_position = world_pos
	crumb.setup(color, TABLE_Y)


## Restart the game: reset the fork, clear crumbs and foods, respawn fresh.
func _restart() -> void:
	_fork.reset()
	_clear_foods()
	_clear_crumbs()
	_busy = false
	for i in _slots.size():
		_spawn_food(i)


func _clear_foods() -> void:
	for i in _foods.size():
		if _foods[i] != null:
			_foods[i].queue_free()
			_foods[i] = null


func _clear_crumbs() -> void:
	for crumb in _crumbs.get_children():
		crumb.queue_free()


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
