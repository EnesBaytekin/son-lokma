class_name HoldChallenge
extends Challenge
## "Tut" challenge: hold E to keep the fork steady. Releasing lets wobble build;
## too much wobble spills crumbs.

const RELEASE_RATE := 1.2      # wobble gained per second while not held
const HOLD_DRAIN := 2.0        # wobble drained per second while held
const SPILL_THRESHOLD := 1.0
const MAX_WOBBLE := 1.6        # wobble never exceeds this (bar recovers instantly)
const MAX_JITTER := 14.0

var _wobble: float = 0.0
var _held: bool = false
var _spill_timer: float = 0.0


func start(in_fork: Fork, in_difficulty: float) -> void:
	super.start(in_fork, in_difficulty)
	_wobble = 0.0
	_held = false
	_spill_timer = 0.0
	_set_hint("E'ye basılı tut! Çatalı sıkı tut.")
	_show_key("E", BAR_YELLOW)
	_update()


func tick(delta: float) -> void:
	if _held:
		_wobble = maxf(0.0, _wobble - HOLD_DRAIN * delta)
	else:
		_wobble = minf(_wobble + RELEASE_RATE * difficulty * delta, MAX_WOBBLE)
	fork.set_jitter(clampf(_wobble, 0.0, 1.5) * MAX_JITTER)
	if _wobble > SPILL_THRESHOLD:
		_spill_timer -= delta
		if _spill_timer <= 0.0:
			_spill_timer = 0.4 / difficulty
			fork.spill()
	_update()


func _update() -> void:
	var stability := 1.0 - clampf(_wobble / 1.6, 0.0, 1.0)
	_set_bar(stability, BAR_GREEN if _held else BAR_YELLOW)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.keycode == KEY_E and not ke.echo:
			get_viewport().set_input_as_handled()
			_held = ke.pressed
