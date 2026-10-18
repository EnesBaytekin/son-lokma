class_name Fork
extends Node2D
## Çatal (fork): flies to a selected food, picks up a bite, then carries it
## off-screen. While carrying, the selected lokma challenge runs (driving the
## fork's jitter and spilling). Which challenge plays is chosen by the food type
## (weighted-random in `_make_challenge`).

signal action_finished(eaten: bool)
signal spilled(world_position: Vector2, color: Color)

enum State { IDLE, GOING_TO_FOOD, STABBING, CARRYING, DROPPING, RETREATING }

const EXIT_X := 2000.0
const APPROACH_SPEED := 700.0
const CARRY_SPEED := 200.0
const DROP_SPEED := 900.0
const DROP_OFF_Y := 1250.0     # below the screen; the fork falls out of view
const RETREAT_SPEED := 700.0   # how fast the empty hand pulls back off-screen

const DROP_BASE_CHANCE := 0.22  # chance an interrupt appears at difficulty 1.0
const DROP_MAX_CHANCE := 0.6    # chance at difficulty 1.6

## The fork approaches straight, then tilts this much while stabbing the bite and
## carries it back at the same tilted angle (scooping from below).
const STAB_ANGLE := 0.2         # radians the visual tilts at the moment of pickup
const STAB_TIME := 0.18         # seconds the tilt takes

const FORK_TEXTURE := preload("res://assets/fork_hand.png")
const HAND_TEXTURE := preload("res://assets/hand.png")

## Difficulty multiplier (0..~2), set by main from fullness before each action.
var difficulty: float = 1.0

var _state: State = State.IDLE
var _held_name: String = ""
var _held_color: Color = Color.WHITE
var _target_food: Food = null
var _target_pos: Vector2 = Vector2.ZERO
var _challenge: Challenge = null
var _interrupt: DropChallenge = null
var _interrupt_x: float = -1.0     # x where the mid-carry interrupt fires
var _drop_crumb_timer: float = 0.0
var _stab_t: float = 0.0

@onready var _visual: Node2D = $Visual
@onready var _body: Sprite2D = $Visual/Body
@onready var _bite: Sprite2D = $Visual/Bite
@onready var _falling_fork: Sprite2D = $Visual/FallingFork


func _ready() -> void:
	position = Vector2(EXIT_X, 540.0)
	_bite.visible = false


## Begin a bite: approach `food` at `food_pos`, pick it up, carry it away.
func start_action(food: Food, food_pos: Vector2) -> void:
	_target_food = food
	_target_pos = food_pos
	_state = State.GOING_TO_FOOD


## Reset to idle: drop any held bite and challenge, park off-screen.
func reset() -> void:
	_clear_challenge()
	_clear_interrupt()
	_interrupt_x = -1.0
	_state = State.IDLE
	_target_food = null
	_held_name = ""
	_held_color = Color.WHITE
	_bite.visible = false
	_visual.position = Vector2.ZERO
	_visual.rotation = 0.0
	_body.texture = FORK_TEXTURE
	_falling_fork.visible = false
	_falling_fork.position = Vector2(611, -260)
	position = Vector2(EXIT_X, 540.0)


## Jitter the fork's visual by `magnitude` pixels (random offset).
func set_jitter(magnitude: float) -> void:
	_visual.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * magnitude


## Sway the fork's visual horizontally by `offset_x` pixels (balance challenge).
func set_sway(offset_x: float) -> void:
	_visual.position = Vector2(offset_x, randf_range(-1.0, 1.0) * 5.0)


## Emit a crumb at the current bite position.
func spill() -> void:
	spilled.emit(_bite.global_position, _held_color)


func _process(delta: float) -> void:
	match _state:
		State.IDLE:
			pass
		State.GOING_TO_FOOD:
			position = position.move_toward(_target_pos, APPROACH_SPEED * delta)
			if position.distance_to(_target_pos) < 6.0:
				_pick_up()
		State.STABBING:
			_stab_t += delta
			_visual.rotation = lerpf(0.0, STAB_ANGLE, clampf(_stab_t / STAB_TIME, 0.0, 1.0))
			if _stab_t >= STAB_TIME:
				_visual.rotation = STAB_ANGLE
				_state = State.CARRYING
		State.CARRYING:
			if _interrupt != null:
				# Frozen during the quick-time: only the drop challenge ticks.
				_interrupt.tick(delta)
				return
			if _interrupt_x >= 0.0 and position.x >= _interrupt_x:
				_spawn_interrupt()
				return
			if _challenge != null and _challenge.is_intro():
				return  # hold still while the player reads the instruction
			position = position.move_toward(Vector2(EXIT_X, position.y), CARRY_SPEED * delta)
			if _challenge != null:
				_challenge.tick(delta)
			if position.x >= EXIT_X - 4.0:
				_finish(true)
		State.DROPPING:
			# The hand stays put; the detached fork falls while spilling crumbs.
			_falling_fork.position.y = move_toward(_falling_fork.position.y, DROP_OFF_Y, DROP_SPEED * delta)
			_drop_crumb_timer -= delta
			if _drop_crumb_timer <= 0.0:
				_drop_crumb_timer = 0.06
				spilled.emit(_falling_fork.to_global(-_body.position), _held_color)
			if _falling_fork.position.y >= DROP_OFF_Y:
				_land_drop()
		State.RETREATING:
			position = position.move_toward(Vector2(EXIT_X, 540.0), RETREAT_SPEED * delta)
			if position.distance_to(Vector2(EXIT_X, 540.0)) < 4.0:
				position = Vector2(EXIT_X, 540.0)
				_visual.position = Vector2.ZERO
				_visual.rotation = 0.0
				_body.texture = FORK_TEXTURE
				_state = State.IDLE


func _pick_up() -> void:
	if _target_food != null:
		_target_food.take_bite()
		_held_name = _target_food.food_name
		_held_color = _target_food.color
	_target_food = null
	_bite.visible = true
	_bite.modulate = _held_color
	_start_challenge()
	_arm_interrupt()
	_stab_t = 0.0
	_state = State.STABBING


func _start_challenge() -> void:
	_clear_challenge()
	_challenge = _make_challenge()
	if _challenge == null:
		return
	add_child(_challenge)
	_challenge.start(self, difficulty)


func _make_challenge() -> Challenge:
	# Weighted-random: the food's "home" challenge is most likely (60%), and the
	# other three carry challenges split the rest. Mash is the joker (no home).
	var home_id: String = _home_challenge_id(_held_name)
	if randf() < 0.6:
		return _new_challenge(home_id)
	var rest: Array[String] = []
	for id in ["tremble", "balance", "hold", "mash"]:
		if id != home_id:
			rest.append(id)
	return _new_challenge(rest[randi() % rest.size()])


func _home_challenge_id(food_name: String) -> String:
	match food_name:
		"kisir":
			return "balance"
		"kek":
			return "hold"
		_:
			return "tremble"  # sarma and any unknown food


func _new_challenge(id: String) -> Challenge:
	match id:
		"balance":
			return BalanceChallenge.new()
		"hold":
			return HoldChallenge.new()
		"mash":
			return MashChallenge.new()
		_:
			return TrembleChallenge.new()


func _clear_challenge() -> void:
	if _challenge != null:
		_challenge.stop()
		_challenge.queue_free()
		_challenge = null


## Decide (difficulty-scaled) whether this carry gets a mid-way drop interrupt,
## and if so where it fires.
func _arm_interrupt() -> void:
	_interrupt_x = -1.0
	var t := clampf((difficulty - 1.0) / 0.6, 0.0, 1.0)
	if randf() < lerpf(DROP_BASE_CHANCE, DROP_MAX_CHANCE, t):
		_interrupt_x = randf_range(1050.0, 1700.0)


## Freeze the carry and show the quick-time; the main challenge is hidden so its
## input stays out of the way until the interrupt resolves.
func _spawn_interrupt() -> void:
	_interrupt_x = -1.0
	if _challenge != null:
		_challenge.visible = false
	_interrupt = DropChallenge.new()
	add_child(_interrupt)
	_interrupt.finished.connect(_on_interrupt_finished)
	_interrupt.start(self, difficulty)


func _on_interrupt_finished(ok: bool) -> void:
	if _interrupt != null:
		_interrupt.stop()
		_interrupt.queue_free()
		_interrupt = null
	if ok:
		if _challenge != null:
			_challenge.visible = true  # resume the carry challenge
		return
	_drop()


func _clear_interrupt() -> void:
	if _interrupt != null:
		_interrupt.stop()
		_interrupt.queue_free()
		_interrupt = null


## The bite is lost: start falling, dropping crumbs on the way down.
func _drop() -> void:
	_clear_challenge()
	_drop_crumb_timer = 0.0
	_bite.visible = false
	_body.texture = HAND_TEXTURE  # the fork is gone; the hand is empty
	_visual.position = Vector2.ZERO  # settle the wobble; the hand stays put
	_falling_fork.position = Vector2(611, -260)
	_falling_fork.visible = true
	_state = State.DROPPING


func _land_drop() -> void:
	_falling_fork.visible = false
	_falling_fork.position = Vector2(611, -260)
	_state = State.IDLE  # empty hand stays put; retreat_hand() pulls it back
	action_finished.emit(false)


## The empty hand pulls back off-screen (called during the teyze's drop recovery).
func retreat_hand() -> void:
	if _state == State.RETREATING:
		return
	_state = State.RETREATING


func _finish(eaten: bool) -> void:
	if eaten and _challenge != null:
		_challenge.finish()
	_clear_challenge()
	_bite.visible = false
	_visual.position = Vector2.ZERO
	_visual.rotation = 0.0
	_state = State.IDLE
	action_finished.emit(eaten)
