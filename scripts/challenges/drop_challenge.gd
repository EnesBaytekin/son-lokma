class_name DropChallenge
extends Challenge
## "Düşürme" interrupt: mid-carry, a random key (F/J/G/K) flashes and must be
## pressed before the window closes. Success -> finished(true), the fork keeps
## carrying. Failure -> finished(false), the fork drops the bite.

const KEYS: Array[int] = [KEY_F, KEY_J, KEY_G, KEY_K]
const KEY_LABELS: Array[String] = ["F", "J", "G", "K"]

const BASE_WINDOW := 2.4          # seconds at difficulty 1.0

var _window: float = 1.1
var _time_left: float = 0.0
var _keycode: int = KEY_F
var _done := false


func start(in_fork: Fork, in_difficulty: float) -> void:
	super.start(in_fork, in_difficulty)
	var idx := randi() % KEYS.size()
	_keycode = KEYS[idx]
	_window = BASE_WINDOW / difficulty
	_time_left = _window
	_done = false
	_set_hint("Çatal kayıyor! Yakala!")
	_show_key(KEY_LABELS[idx], BAR_RED)
	_set_bar(1.0, BAR_RED)
	_hide_counter()


## No "get ready" pause: the drop quick-time must stay a surprise.
func _wants_intro() -> bool:
	return false


func tick(delta: float) -> void:
	if _done:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_done = true
		finished.emit(false)
		return
	var p := _time_left / _window
	_set_bar(p, BAR_RED if p < 0.4 else BAR_YELLOW)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _done:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == _keycode:
			get_viewport().set_input_as_handled()
			_done = true
			finished.emit(true)
