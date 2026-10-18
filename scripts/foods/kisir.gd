extends Food
## Kisir (bulgur salad).


func _init() -> void:
	food_name = "kisir"
	state_count = 5
	color = Color(0.788, 0.416, 0.165)
	bite_texture = preload("res://assets/foods/kisir/kisir-parca1.png")
	crumb_texture = preload("res://assets/foods/kisir/kisir-parca2.png")
