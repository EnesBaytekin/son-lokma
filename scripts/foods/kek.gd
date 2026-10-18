extends Food
## Islak kek (wet chocolate cake).


func _init() -> void:
	food_name = "kek"
	state_count = 5
	color = Color(0.42, 0.259, 0.149)
	bite_texture = preload("res://assets/foods/kek/kek-parca1.png")
	crumb_texture = preload("res://assets/foods/kek/kek-parca2.png")
