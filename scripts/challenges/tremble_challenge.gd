class_name TrembleChallenge
extends Challenge
## "Titreme" challenge: the fork trembles while carrying; spam SPACE to keep it
## steady. Tremble builds over time and spills crumbs when too high.

const TREMBLE_RATE := 0.7          # tremble gained per second
const SPACE_REDUCTION := 0.3       # tremble removed per space press
const SPILL_THRESHOLD := 1.0       # spill only while above this
const MAX_JITTER := 14.0           # max visual jitter in pixels

var _tremble: float = 0.0
var _spill_timer: float = 0.0


func start(in_fork: Fork, in_difficulty: float) -> void:
	super.start(in_fork, in_difficulty)
	_tremble = 0.0
	_spill_timer = 0.0
	_set_hint("SPACE'e bas! Çatalı sabit tut.")
	_set_bar(1.0, BAR_GREEN)


func tick(delta: float) -> void:
	_tremble += TREMBLE_RATE * difficulty * delta
	fork.set_jitter(clampf(_tremble, 0.0, 1.5) * MAX_JITTER)
	_set_bar(1.0 - clampf(_tremble / (SPILL_THRESHOLD + 0.6), 0.0, 1.0), BAR_GREEN)
	if _tremble > SPILL_THRESHOLD:
		_spill_timer -= delta
		if _spill_timer <= 0.0:
			_spill_timer = _spill_interval()
			fork.spill()


func _spill_interval() -> float:
	return clampf(0.5 / (_tremble - SPILL_THRESHOLD), 0.05, 0.4)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_SPACE:
			_tremble = maxf(0.0, _tremble - SPACE_REDUCTION)
			get_viewport().set_input_as_handled()
