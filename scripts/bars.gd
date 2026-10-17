class_name Bars
extends CanvasLayer
## Top HUD: fullness (şişkinlik) bar on the left with a threshold line, and the
## teyze's mood bar on the right. Purely presentational — main owns the values.

const BAR_W := 420.0
const BAR_H := 30.0

const COLOR_GREEN := Color(0.42, 0.85, 0.45)
const COLOR_YELLOW := Color(1.0, 0.82, 0.15)
const COLOR_RED := Color(1.0, 0.3, 0.25)

var _threshold: float = 65.0

var _fullness_bg: ColorRect
var _fullness_fill: ColorRect
var _threshold_line: ColorRect
var _mood_bg: ColorRect
var _mood_fill: ColorRect


func _ready() -> void:
	_build()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var fl := _label(Vector2(40, 26), Vector2(300, 30), 26, Color(1.0, 0.96, 0.85), HORIZONTAL_ALIGNMENT_LEFT)
	fl.text = "Şişkinlik"
	root.add_child(fl)

	_fullness_bg = ColorRect.new()
	_fullness_bg.color = Color(0.0, 0.0, 0.0, 0.55)
	_fullness_bg.position = Vector2(40, 62)
	_fullness_bg.size = Vector2(BAR_W, BAR_H)
	root.add_child(_fullness_bg)

	_fullness_fill = ColorRect.new()
	_fullness_fill.position = _fullness_bg.position + Vector2(2, 2)
	_fullness_fill.size = Vector2(0, BAR_H - 4)
	root.add_child(_fullness_fill)

	_threshold_line = ColorRect.new()
	_threshold_line.color = Color(1.0, 1.0, 1.0, 0.85)
	_threshold_line.size = Vector2(3, BAR_H)
	root.add_child(_threshold_line)

	var ml := _label(Vector2(1920 - 340, 26), Vector2(300, 30), 26, Color(1.0, 0.96, 0.85), HORIZONTAL_ALIGNMENT_RIGHT)
	ml.text = "Teyze"
	root.add_child(ml)

	_mood_bg = ColorRect.new()
	_mood_bg.color = Color(0.0, 0.0, 0.0, 0.55)
	_mood_bg.position = Vector2(1920 - 40 - BAR_W, 62)
	_mood_bg.size = Vector2(BAR_W, BAR_H)
	root.add_child(_mood_bg)

	_mood_fill = ColorRect.new()
	_mood_fill.position = _mood_bg.position + Vector2(2, 2)
	_mood_fill.size = Vector2(0, BAR_H - 4)
	root.add_child(_mood_fill)


func _label(pos: Vector2, size: Vector2, font_size: int, color: Color, align: int) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = size
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = align
	return lbl


## Place the threshold marker once (the value never changes during play).
func set_threshold(threshold: float) -> void:
	_threshold = threshold
	var p := clampf(threshold / 100.0, 0.0, 1.0)
	_threshold_line.position = _fullness_bg.position + Vector2(2.0 + (BAR_W - 4.0) * p, 0.0)


func set_fullness(value: float) -> void:
	var p := clampf(value / 100.0, 0.0, 1.0)
	_fullness_fill.size.x = (BAR_W - 4.0) * p
	_fullness_fill.color = _fullness_color(value)


func set_mood(value: float) -> void:
	var p := clampf(value / 100.0, 0.0, 1.0)
	_mood_fill.size.x = (BAR_W - 4.0) * p
	_mood_fill.color = _mood_color(value)


func _fullness_color(value: float) -> Color:
	if value >= 90.0:
		return COLOR_RED
	if value >= _threshold:
		return COLOR_YELLOW
	return COLOR_GREEN


func _mood_color(value: float) -> Color:
	if value >= 60.0:
		return COLOR_GREEN
	if value >= 30.0:
		return COLOR_YELLOW
	return COLOR_RED
