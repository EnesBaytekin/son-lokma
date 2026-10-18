class_name Teyze
extends Node2D
## Tonton teyze (the sweet auntie): stands behind the table, above the plate.
## When a food runs out she says a line, walks off-screen, then returns to
## refill the slot (unless the player refuses first). She's happy by default and
## briefly shows a sad face after something goes wrong (a spill or a dropped
## fork), then smiles again.

signal left      # reached off-screen (after leave())
signal returned  # back at home (after come_back())

enum State { HOME, LEAVING, GONE, RETURNING }

const HOME_POS := Vector2(1400.0, 495.0)  # her feet; head sits just under the top
const GONE_POS := Vector2(2200.0, 495.0)
const MOVE_SPEED := 720.0
const BUBBLE_TIME := 1.4
const SAD_TIME := 3.0

const HAPPY_TEXTURE := preload("res://assets/teyze.png")
const SAD_TEXTURE := preload("res://assets/teyze-mutsuz.png")

## Cliché auntie small-talk, said at random while she's home and free.
const CHATTER_LINES: Array[String] = [
	"Evlilik ne zaman?",
	"Okulu ne yaptın?",
	"Sen kaçıncı sınıf oldun şimdi?",
	"Anan baban nasıl?",
	"Komşunun kızı evlendi, senden haber yok.",
	"İşler nasıl gidiyor?",
	"Yemeğin soğuyacak, hadi ye.",
	"Ben senin yaşında üç çocuk büyütmüştüm.",
	"Torun torba sahibi olacaksın artık.",
	"Bak hâlâ bekar geziyorsun.",
]
const CHATTER_MIN := 6.0   # shortest wait between two chit-chats
const CHATTER_MAX := 13.0  # longest wait

var _state: State = State.HOME
var _bubble_timer: float = 0.0
var _sad_timer: float = 0.0
var _chatter_timer: float = 0.0
var _chatter_bag: Array[String] = []
var _last_chatter_line: String = ""

@onready var _bubble: Label = $BubbleLayer/Bubble
@onready var _body: Sprite2D = $Body


func _ready() -> void:
	position = HOME_POS
	_setup_bubble()
	_bubble.visible = false
	happy()
	_chatter_timer = randf_range(CHATTER_MIN, CHATTER_MAX)


func _setup_bubble() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.95)
	style.border_color = Color(0.25, 0.2, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	_bubble.add_theme_stylebox_override("normal", style)
	_bubble.add_theme_color_override("font_color", Color(0.15, 0.1, 0.1))
	_bubble.add_theme_font_size_override("font_size", 28)


## Show a speech bubble with `text` for a moment, beside her head (not covering
## her face). The bubble lives on its own top-most canvas layer, so the action
## text in the middle of the screen never covers it.
func say(text: String) -> void:
	_bubble.text = text
	_bubble.reset_size()
	var local_offset := Vector2(-_bubble.size.x - 100.0, -360.0 - _bubble.size.y)
	_bubble.position = get_global_transform_with_canvas() * local_offset
	_bubble.visible = true
	_bubble_timer = BUBBLE_TIME


## Show the happy face immediately (and cancel any pending sad reaction).
func happy() -> void:
	_sad_timer = 0.0
	_body.texture = HAPPY_TEXTURE


## Show the sad face for `seconds`, then smile again.
func sad(seconds: float = SAD_TIME) -> void:
	_sad_timer = seconds
	_body.texture = SAD_TEXTURE


## Draw the next small-talk line from a shuffled bag, so it never repeats the
## previous line (feels random without back-to-back duplicates).
func _next_chatter_line() -> String:
	if _chatter_bag.is_empty():
		_chatter_bag = CHATTER_LINES.duplicate()
		_chatter_bag.shuffle()
		if _chatter_bag.size() > 1 and _chatter_bag[0] == _last_chatter_line:
			_chatter_bag.push_back(_chatter_bag.pop_front())
	var line: String = _chatter_bag.pop_front()
	_last_chatter_line = line
	return line


## Walk off-screen; emits `left` once gone.
func leave() -> void:
	_state = State.LEAVING
	_bubble.visible = false


## Walk back home; emits `returned` once back.
func come_back() -> void:
	_state = State.RETURNING


## Snap back home and clear any speech/movement/sadness (used on restart).
func reset() -> void:
	_state = State.HOME
	position = HOME_POS
	_bubble.visible = false
	_bubble_timer = 0.0
	_chatter_timer = randf_range(CHATTER_MIN, CHATTER_MAX)
	happy()


func _process(delta: float) -> void:
	# The sad face always counts back to happy, even while walking.
	if _sad_timer > 0.0:
		_sad_timer -= delta
		if _sad_timer <= 0.0:
			_body.texture = HAPPY_TEXTURE
	# Random small-talk while home and free (not mid-refill or already speaking).
	_chatter_timer -= delta
	if _chatter_timer <= 0.0:
		_chatter_timer = randf_range(CHATTER_MIN, CHATTER_MAX)
		if _state == State.HOME and not _bubble.visible:
			say(_next_chatter_line())
	match _state:
		State.HOME:
			if _bubble.visible:
				_bubble_timer -= delta
				if _bubble_timer <= 0.0:
					_bubble.visible = false
		State.LEAVING:
			position = position.move_toward(GONE_POS, MOVE_SPEED * delta)
			if position.distance_to(GONE_POS) < 4.0:
				_state = State.GONE
				left.emit()
		State.GONE:
			pass
		State.RETURNING:
			position = position.move_toward(HOME_POS, MOVE_SPEED * delta)
			if position.distance_to(HOME_POS) < 4.0:
				position = HOME_POS
				_state = State.HOME
				returned.emit()
