class_name Food
extends Node2D
## Base class for every food placed on the plate.
##
## Each concrete food (sarma, kisir, kek) is its own scene/script and
## only sets `food_name`, `state_count` and `color`. Textures follow the
## convention
##     res://assets/foods/<food_name>/<food_name>_<i>.png
## where i == 0 is full and i == state_count - 1 is the last bite.
## Swap the placeholder PNGs for real art with the same names.

## Emitted when the food runs out (bites_left reaches 0).
signal emptied(food: Food)

## Folder name under res://assets/foods/ and texture prefix.
var food_name: String = "food"
## Number of visual states, equal to the number of bites when full.
var state_count: int = 3
## Tint used for placeholder visuals (fork bite, spilled crumbs).
var color: Color = Color.WHITE
## Optional per-food art: the bite shown on the fork and the pieces spilled on
## the table. When null, the generic tinted crumb is used instead.
var bite_texture: Texture2D = null
var crumb_texture: Texture2D = null
var bite_scale := Vector2.ONE

var bites_left: int = 0
var _textures: Array[Texture2D] = []

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_load_textures()
	bites_left = state_count
	_update_sprite()


func _load_textures() -> void:
	_textures.clear()
	for i in range(state_count):
		var path := "res://assets/foods/%s/%s_%d.png" % [food_name, food_name, i]
		var tex: Texture2D = load(path)
		if tex == null:
			push_warning("Food: missing texture %s" % path)
		_textures.append(tex)


## Take one bite: decreases bites_left and refreshes the sprite.
## Emits `emptied` when the food is finished.
func take_bite() -> void:
	if bites_left <= 0:
		return
	bites_left -= 1
	_update_sprite()
	if bites_left <= 0:
		emptied.emit(self)


func _update_sprite() -> void:
	# 0 when full, state_count - 1 when one bite is left.
	var idx := state_count - bites_left
	if idx >= 0 and idx < _textures.size() and sprite != null:
		sprite.texture = _textures[idx]
