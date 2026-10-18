class_name Challenge
extends CanvasLayer
## Base class for the "lokma" (bite) challenges shown while the fork carries a
## bite, and for the mid-carry drop interrupt. Each subclass builds a small
## overlay (instruction + progress bar + optional key/counter) and drives the
## fork's jitter/spill through `fork.set_jitter()` / `fork.spill()`.

signal spilled                  # carry challenges: request a crumb
signal finished(ok: bool)       # interrupts: true = caught, false = dropped

const BAR_BG := Color(0.0, 0.0, 0.0, 0.55)
const BAR_GREEN := Color(0.42, 0.85, 0.45)
const BAR_YELLOW := Color(1.0, 0.82, 0.15)
const BAR_RED := Color(1.0, 0.3, 0.25)
const HINT_COLOR := Color(1.0, 0.96, 0.85)

const INTRO_TIME := 0.8   # seconds the instruction shows before the action starts

var fork: Fork
var difficulty: float = 1.0

var _root: Control
var _hint: Label
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _key: Label
var _counter: Label
var _intro_label: Label
var _bar_w: float = 600.0
var _intro: float = 0.0


func _ready() -> void:
	_build_ui()
	visible = false


func start(in_fork: Fork, in_difficulty: float) -> void:
	fork = in_fork
	difficulty = in_difficulty
	visible = true
	_intro = INTRO_TIME if _wants_intro() else 0.0
	_intro_label.visible = _intro > 0.0
	if _intro > 0.0:
		_intro_label.text = "3"


## Carry challenges announce themselves before starting; the drop quick-time
## overrides this to false (it must stay a surprise).
func _wants_intro() -> bool:
	return true


func _process(delta: float) -> void:
	if _intro <= 0.0:
		return
	_intro -= delta
	if _intro <= 0.0:
		_intro = 0.0
		_intro_label.visible = false
		return
	var n := clampi(int(ceilf(_intro / (INTRO_TIME / 3.0))), 1, 3)
	_intro_label.text = str(n)


## True while the challenge is still showing its "get ready" intro; the fork
## holds still until this turns false.
func is_intro() -> bool:
	return _intro > 0.0


func stop() -> void:
	visible = false


func tick(_delta: float) -> void:
	pass


## Called by the fork right before the carry ends (before the bite is hidden),
## so a challenge can evaluate its result (e.g. mash counts presses).
func finish() -> void:
	pass


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_hint = _make_label(Vector2(0, 90), Vector2(1920, 80), 46, HINT_COLOR)
	_root.add_child(_hint)

	_bar_bg = ColorRect.new()
	_bar_bg.color = BAR_BG
	_bar_bg.position = Vector2(660, 200)
	_bar_bg.size = Vector2(_bar_w, 36)
	_root.add_child(_bar_bg)

	_bar_fill = ColorRect.new()
	_bar_fill.position = _bar_bg.position + Vector2(3, 3)
	_bar_fill.size = Vector2(0, 30)
	_root.add_child(_bar_fill)

	_key = _make_label(Vector2(0, 280), Vector2(1920, 170), 120, BAR_YELLOW)
	_key.visible = false
	_root.add_child(_key)

	_counter = _make_label(Vector2(0, 470), Vector2(1920, 70), 44, Color.WHITE)
	_counter.visible = false
	_root.add_child(_counter)

	_intro_label = _make_label(Vector2(0, 520), Vector2(1920, 120), 96, Color(1.0, 0.6, 0.2))
	_intro_label.visible = false
	_root.add_child(_intro_label)


func _make_label(pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl


func _set_hint(text: String) -> void:
	_hint.text = text


func _set_bar(progress: float, color: Color) -> void:
	var p := clampf(progress, 0.0, 1.0)
	_bar_fill.size.x = (_bar_w - 6.0) * p
	_bar_fill.color = color


func _show_key(text: String, color: Color) -> void:
	_key.text = text
	_key.add_theme_color_override("font_color", color)
	_key.visible = true


func _hide_key() -> void:
	_key.visible = false


func _set_counter(text: String) -> void:
	_counter.text = text
	_counter.visible = true


func _hide_counter() -> void:
	_counter.visible = false
