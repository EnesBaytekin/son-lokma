class_name Crumb
extends Node2D
## A spilled food crumb: falls with gravity, lands on the table, and stays.

const GRAVITY := 900.0

var _table_y := 1020.0
var _velocity := Vector2.ZERO
var _settled := false

@onready var _sprite: Sprite2D = $Sprite2D


func setup(color: Color, table_y: float) -> void:
	_sprite.modulate = color
	_table_y = table_y
	_sprite.scale = Vector2.ONE * randf_range(0.5, 1.1)
	_velocity = Vector2(randf_range(-50.0, 50.0), randf_range(-140.0, -60.0))


func _physics_process(delta: float) -> void:
	if _settled:
		return
	_velocity.y += GRAVITY * delta
	position += _velocity * delta
	if position.y >= _table_y:
		position.y = _table_y
		_settled = true
		set_physics_process(false)
