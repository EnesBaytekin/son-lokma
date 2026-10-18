class_name Crumb
extends Node2D
## A spilled food crumb: falls with gravity, lands on the table, rests for a
## moment, then slowly fades away.

const GRAVITY := 900.0
const DEFAULT_TEXTURE := preload("res://assets/crumb.png")
const FADE_DELAY := 4.0   # seconds to rest on the table before fading
const FADE_TIME := 1.5    # seconds the fade-out takes

var _table_y := 1020.0
var _x_max := 1e9
var _velocity := Vector2.ZERO
var _settled := false
var _fade_timer := 0.0
var _alpha := 1.0

@onready var _sprite: Sprite2D = $Sprite2D


func setup(color: Color, texture: Texture2D, table_y_min: float, table_y_max: float, x_max: float) -> void:
	if texture != null:
		_sprite.texture = texture
		_sprite.modulate = Color.WHITE
		_sprite.scale = Vector2.ONE * randf_range(0.6, 0.9)
	else:
		_sprite.texture = DEFAULT_TEXTURE
		_sprite.modulate = color
		_sprite.scale = Vector2.ONE * randf_range(0.5, 1.1)
	# Land at a random height on the table surface so the pieces look scattered
	# across the sehpa instead of all resting on one fixed line.
	_table_y = randf_range(table_y_min, table_y_max)
	_x_max = x_max
	_velocity = Vector2(randf_range(-80.0, 80.0), randf_range(-160.0, -70.0))
	_fade_timer = FADE_DELAY


func _physics_process(delta: float) -> void:
	if _settled:
		return
	_velocity.y += GRAVITY * delta
	position += _velocity * delta
	position.x = minf(position.x, _x_max)
	if position.y >= _table_y:
		position.y = _table_y
		_settled = true
		set_physics_process(false)


func _process(delta: float) -> void:
	if not _settled:
		return
	_fade_timer -= delta
	if _fade_timer > 0.0:
		return
	_alpha = maxf(0.0, _alpha - delta / FADE_TIME)
	_sprite.modulate.a = _alpha
	if _alpha <= 0.0:
		queue_free()
