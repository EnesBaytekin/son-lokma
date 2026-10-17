class_name HayirChallenge
extends CanvasLayer
## "HAYIR" typing challenge. Shows "hayır" in a random mix of upper/lower case;
## the player types it back with matching case (Shift / Caps Lock) before the
## auntie returns. Emits `completed` on success.

signal completed

const WORD := "hayır"  # contains the Turkish dotless ı (U+0131)
const VALID_CHARS := "hayırHAYIR"

var _target: String = ""
var _index: int = 0
var _active: bool = false

var _prompt: Label
var _word: RichTextLabel


func _ready() -> void:
	_prompt = Label.new()
	_prompt.text = "Teyze gelmeden aynısını yaz:"
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 34)
	_prompt.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))
	_prompt.position = Vector2(0, 150)
	_prompt.size = Vector2(1920, 60)
	add_child(_prompt)

	_word = RichTextLabel.new()
	_word.bbcode_enabled = true
	_word.scroll_active = false
	_word.add_theme_font_size_override("normal_font_size", 96)
	_word.position = Vector2(0, 240)
	_word.size = Vector2(1920, 140)
	add_child(_word)

	set_visible(false)


func start() -> void:
	_target = _random_case(WORD)
	_index = 0
	_active = true
	_refresh()
	set_visible(true)


func stop() -> void:
	_active = false
	set_visible(false)


func is_active() -> bool:
	return _active


func _random_case(word: String) -> String:
	var out := ""
	for ch in word:
		out += ch if randf() < 0.5 else ch.to_upper()
	return out


func _refresh() -> void:
	var typed := _target.substr(0, _index)
	var next_ch := _target.substr(_index, 1)
	var rest := _target.substr(_index + 1)
	var bb := "[center]"
	if typed != "":
		bb += "[color=#6fd982]" + typed + "[/color]"
	if next_ch != "":
		bb += "[u][b]" + next_ch + "[/b][/u]"
	if rest != "":
		bb += rest
	bb += "[/center]"
	_word.text = bb


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


func _char_from_event(event: InputEventKey) -> String:
	if event.unicode == 0:
		return ""
	var ch := String.chr(event.unicode)
	# If the engine reports the base (lowercase) char while Shift is held, use
	# the shifted form instead. 'ı'.to_upper() == 'I'.
	if event.shift_pressed and ch == ch.to_lower():
		return ch.to_upper()
	return ch
