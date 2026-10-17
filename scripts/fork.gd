class_name Fork
extends Node2D
## Çatal (fork): flies to a selected food, picks up a bite, then carries it
## off-screen. While carrying, the player spams SPACE to keep the fork from
## trembling and spilling. Which action plays is chosen by the held food type.

signal action_finished
signal spilled(world_position: Vector2, color: Color)

enum State { IDLE, GOING_TO_FOOD, CARRYING }

const EXIT_X := 2000.0
const APPROACH_SPEED := 700.0
const CARRY_SPEED := 180.0

const TREMBLE_RATE := 0.7          # tremble gained per second
const SPACE_REDUCTION := 0.16      # tremble removed per space press
const SPILL_THRESHOLD := 1.0       # spill only while above this
const MAX_JITTER := 14.0           # max visual jitter in pixels

var _state: State = State.IDLE
var _held_name: String = ""
var _held_color: Color = Color.WHITE
var _target_food: Food = null
var _target_pos: Vector2 = Vector2.ZERO
var _tremble: float = 0.0
var _spill_timer: float = 0.0

@onready var _visual: Node2D = $Visual
@onready var _bite: Sprite2D = $Visual/Bite


func _ready() -> void:
	position = Vector2(EXIT_X, 540.0)
	_bite.visible = false


## Begin a bite: approach `food` at `food_pos`, pick it up, carry it away.
func start_action(food: Food, food_pos: Vector2) -> void:
	_target_food = food
	_target_pos = food_pos
	_tremble = 0.0
	_spill_timer = 0.0
	_state = State.GOING_TO_FOOD


## Reset to idle: drop any held bite, hide it, and park off-screen.
func reset() -> void:
	_state = State.IDLE
	_target_food = null
	_held_name = ""
	_held_color = Color.WHITE
	_tremble = 0.0
	_spill_timer = 0.0
	_bite.visible = false
	_visual.position = Vector2.ZERO
	position = Vector2(EXIT_X, 540.0)


func _process(delta: float) -> void:
	match _state:
		State.IDLE:
			pass
		State.GOING_TO_FOOD:
			position = position.move_toward(_target_pos, APPROACH_SPEED * delta)
			if position.distance_to(_target_pos) < 6.0:
				_pick_up()
		State.CARRYING:
			position = position.move_toward(Vector2(EXIT_X, position.y), CARRY_SPEED * delta)
			_tick_carry_action(delta)
			if position.x >= EXIT_X - 4.0:
				_finish()


func _unhandled_input(event: InputEvent) -> void:
	if _state != State.CARRYING:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_SPACE:
			_tremble = maxf(0.0, _tremble - SPACE_REDUCTION)


func _pick_up() -> void:
	if _target_food != null:
		_target_food.take_bite()
		_held_name = _target_food.food_name
		_held_color = _target_food.color
	_target_food = null
	_bite.visible = true
	_bite.modulate = _held_color
	_state = State.CARRYING


## Currently every food uses the same "tremble" action. Later this will
## dispatch on `_held_name` so each food can have its own action.
func _tick_carry_action(delta: float) -> void:
	_tick_tremble(delta)


func _tick_tremble(delta: float) -> void:
	_tremble += TREMBLE_RATE * delta
	_update_jitter()
	_update_spilling(delta)


func _update_jitter() -> void:
	var magnitude := clampf(_tremble, 0.0, 1.5) * MAX_JITTER
	_visual.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * magnitude


func _update_spilling(delta: float) -> void:
	if _tremble <= SPILL_THRESHOLD:
		return
	_spill_timer -= delta
	if _spill_timer <= 0.0:
		_spill_timer = _spill_interval()
		spilled.emit(_bite.global_position, _held_color)


func _spill_interval() -> float:
	return clampf(0.5 / (_tremble - SPILL_THRESHOLD), 0.05, 0.4)


func _finish() -> void:
	_bite.visible = false
	_visual.position = Vector2.ZERO
	_state = State.IDLE
	action_finished.emit()
