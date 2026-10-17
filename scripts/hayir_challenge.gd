class_name HayirChallenge
extends CanvasLayer
## "HAYIR" typing challenge. Shows "hayır" in a random mix of upper/lower case;
## the player types it back with matching case (Shift / Caps Lock) before the
## auntie returns. Typed letters go green, the next one is yellow, the rest are
## white. A wrong press flashes the current letter red and shakes it. Completing
## the word emits `completed`.

signal completed

const WORD := "hayır"  # contains the Turkish dotless ı (U+0131)
const VALID_CHARS := "hayırHAYIR"

const CHAR_FONT_SIZE := 130
const CELL_W := 120.0
const CELL_H := 180.0
const GAP := 16.0
const WORD_Y := 300.0
const SHAKE_AMOUNT := 16.0

const COLOR_TYPED := Color(0.35, 0.85, 0.45)   # green
const COLOR_CURRENT := Color(1.0, 0.82, 0.15)  # yellow
const COLOR_UNTYPED := Color(1.0, 1.0, 1.0)    # white
const COLOR_WRONG := Color(1.0, 0.3, 0.25)     # red

var _target: String = ""
var _index: int = 0
var _active: bool = false

var _prompt: Label
var _char_labels: Array[Label] = []
var _bold_font: FontVariation
var _shake_tween: Tween


func _ready() -> void:
	_bold_font = FontVariation.new()
	_bold_font.base_font = ThemeDB.fallback_font
	_bold_font.variation_embolden = 0.8
	_build_ui()
	set_visible(false)


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var backdrop := Panel.new()
	backdrop.add_theme_stylebox_override("panel", _make_panel_style())
	backdrop.position = Vector2(480, 150)
	backdrop.size = Vector2(960, 380)
	root.add_child(backdrop)

	_prompt = Label.new()
	_prompt.text = "Teyze gelmeden aynısını yaz:"
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 42)
	_prompt.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
	_prompt.position = Vector2(0, 200)
	_prompt.size = Vector2(1920, 70)
	root.add_child(_prompt)

	for _i in WORD.length():
		var lbl := Label.new()
		lbl.add_theme_font_override("font", _bold_font)
		lbl.add_theme_font_size_override("font_size", CHAR_FONT_SIZE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size = Vector2(CELL_W, CELL_H)
		root.add_child(lbl)
		_char_labels.append(lbl)

	_layout_chars()


func _make_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.06, 0.55)
	sb.set_corner_radius_all(24)
	sb.border_color = Color(1.0, 1.0, 1.0, 0.08)
	sb.set_border_width_all(1)
	return sb


func _layout_chars() -> void:
	var total := _char_labels.size() * CELL_W + (_char_labels.size() - 1) * GAP
	var start_x := (1920.0 - total) * 0.5
	for i in _char_labels.size():
		_char_labels[i].position = Vector2(start_x + i * (CELL_W + GAP), WORD_Y)


func _char_x(i: int) -> float:
	var total := _char_labels.size() * CELL_W + (_char_labels.size() - 1) * GAP
	var start_x := (1920.0 - total) * 0.5
	return start_x + i * (CELL_W + GAP)


func start() -> void:
	_target = _random_case(WORD)
	_index = 0
	_active = true
	_layout_chars()
	_refresh()
	set_visible(true)


func stop() -> void:
	_active = false
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	set_visible(false)


func is_active() -> bool:
	return _active


func _random_case(word: String) -> String:
	var out := ""
	for ch in word:
		out += ch if randf() < 0.5 else ch.to_upper()
	return out


func _refresh() -> void:
	for i in _char_labels.size():
		var lbl := _char_labels[i]
		lbl.text = _target[i]
		if i < _index:
			lbl.add_theme_color_override("font_color", COLOR_TYPED)
		elif i == _index:
			lbl.add_theme_color_override("font_color", COLOR_CURRENT)
		else:
			lbl.add_theme_color_override("font_color", COLOR_UNTYPED)


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var ch := _char_from_event(event as InputEventKey)
	if ch == "" or not (ch in VALID_CHARS):
		return
	# Consume the key so the game does not also read it.
	get_viewport().set_input_as_handled()
	if ch == _target[_index]:
		_index += 1
		_refresh()
		if _index >= _target.length():
			_active = false
			completed.emit()
	else:
		_flash_wrong()


func _flash_wrong() -> void:
	var idx := _index
	var lbl := _char_labels[idx]
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	var base_x := _char_x(idx)
	lbl.position.x = base_x
	lbl.add_theme_color_override("font_color", COLOR_WRONG)
	_shake_tween = create_tween()
	for _i in 3:
		_shake_tween.tween_property(lbl, "position:x", base_x + SHAKE_AMOUNT, 0.05)
		_shake_tween.tween_property(lbl, "position:x", base_x - SHAKE_AMOUNT, 0.05)
	_shake_tween.tween_property(lbl, "position:x", base_x, 0.05)
	_shake_tween.tween_callback(func() -> void:
		if _active and _index == idx:
			lbl.add_theme_color_override("font_color", COLOR_CURRENT))


func _char_from_event(event: InputEventKey) -> String:
	if event.unicode == 0:
		return ""
	var ch := String.chr(event.unicode)
	# If the engine reports the base (lowercase) char while Shift is held, use
	# the shifted form instead. 'ı'.to_upper() == 'I'.
	if event.shift_pressed and ch == ch.to_lower():
		return ch.to_upper()
	return ch
