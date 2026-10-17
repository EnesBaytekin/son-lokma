class_name Teyze
extends Node2D
## Tonton teyze (the sweet auntie): sits across the table, behind the plate.
## When a food runs out she says a line, walks off-screen, then returns to
## refill the slot (unless the player refuses first).

signal left      # reached off-screen (after leave())
signal returned  # back at home (after come_back())

enum State { HOME, LEAVING, GONE, RETURNING }

const HOME_POS := Vector2(1720.0, 250.0)
const GONE_POS := Vector2(2200.0, 250.0)
const MOVE_SPEED := 720.0
const BUBBLE_TIME := 1.4

var _state: State = State.HOME
var _bubble_timer: float = 0.0

@onready var _bubble: Label = $Bubble


func _ready() -> void:
	position = HOME_POS
	_setup_bubble()
	_bubble.visible = false


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


## Show a speech bubble with `text` for a moment.
func say(text: String) -> void:
	_bubble.text = text
	_bubble.reset_size()
	_bubble.position = Vector2(-_bubble.size.x * 0.5, -120.0 - _bubble.size.y)
	_bubble.visible = true
	_bubble_timer = BUBBLE_TIME


## Walk off-screen; emits `left` once gone.
func leave() -> void:
	_state = State.LEAVING
	_bubble.visible = false


## Walk back home; emits `returned` once back.
func come_back() -> void:
	_state = State.RETURNING


## Snap back home and clear any speech/movement (used on restart).
func reset() -> void:
	_state = State.HOME
	position = HOME_POS
	_bubble.visible = false
	_bubble_timer = 0.0


func _process(delta: float) -> void:
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
