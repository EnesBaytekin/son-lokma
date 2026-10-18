class_name MashChallenge
extends Challenge
## "Ez" challenge: mash X enough times before the bite reaches the mouth. If you
## fall short, the fork spills a burst of crumbs at the end of the carry.

const BASE_REQUIRED := 13

var _required: int = 7
var _presses: int = 0


func start(in_fork: Fork, in_difficulty: float) -> void:
	super.start(in_fork, in_difficulty)
	_required = maxi(4, int(BASE_REQUIRED * difficulty))
	_presses = 0
	_set_hint("X'e hızlıca bas! %d kere." % _required)
	_show_key("X", BAR_YELLOW)
	_set_counter("0 / %d" % _required)
	_set_bar(0.0, BAR_YELLOW)


func tick(_delta: float) -> void:
	fork.set_jitter(4.0)  # light constant wobble for flavor


func finish() -> void:
	if _presses < _required:
		var misses := _required - _presses
		for _i in clampi(misses, 1, 4):
			fork.spill()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_X:
			get_viewport().set_input_as_handled()
			_presses += 1
			_set_counter("%d / %d" % [_presses, _required])
			_set_bar(float(_presses) / float(_required), BAR_GREEN)
