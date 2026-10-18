extends Food
## Yaprak sarmasi (stuffed grape leaves).


func _init() -> void:
	food_name = "sarma"
	state_count = 5
	color = Color(0.29, 0.486, 0.247)
	bite_texture = preload("res://assets/foods/sarma/sarma_parca1.png")
	crumb_texture = preload("res://assets/foods/sarma/sarma_parca2.png")
