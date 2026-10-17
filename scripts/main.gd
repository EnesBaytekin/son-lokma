extends Node2D
## Son Lokma — a plate with three food slots, a fork, and a tonton teyze.
##
## Keys 1 / 2 / 3 pick a slot: the fork flies there, takes a bite, and carries
## it off-screen. During the carry, SPACE keeps the fork from trembling/spilling.
## When a food runs out, the teyze offers a refill; type "hayır" (with the exact
## random casing) before she returns to refuse it and close the slot. Empty the
## whole plate to win. F5 restarts.

const FOOD_SCENES: Array[PackedScene] = [
	preload("res://scenes/foods/sarma.tscn"),
	preload("res://scenes/foods/kisir.tscn"),
	preload("res://scenes/foods/kek.tscn"),
]

const CRUMB_SCENE: PackedScene = preload("res://scenes/crumb.tscn")
const TABLE_Y := 1020.0

const REFILL_LINES: Array[String] = [
	"Dur, hemen tazeleyeyim!",
	"Bitmiş, şimdi yenilerim.",
	"Aç kaldın, hemen getiriyorum.",
	"Dur dur, doldurayım şu tabağı.",
	"Az kalmış, tazeliyorum hemen.",
	"Bir tane daha koyayım mı?",
]
const TALK_TIME := 1.4    # speech bubble shows before the auntie leaves
const GONE_TIME := 4.0    # how long the auntie stays off-screen (typing window)

const DROP_LINES: Array[String] = [
	"Ah, çatal düştü! Dur, yenisini getiriyorum.",
	"Olsun, hemen yeni çatal getiriyorum.",
	"Çatal düşürdün! Neyse, yenisi geliyor.",
	"Dikkat et! Hemen yenisini alıyorum.",
]

const FULLNESS_THRESHOLD := 65.0   # past this, eating gets harder
const FULLNESS_PER_BITE := 7.0
const MOOD_START := 70.0
const MOOD_PER_BITE := 4.0
const MOOD_PER_FOOD := 8.0
const MOOD_PER_SPILL := 6.0
const MOOD_PER_DROP := 15.0

@onready var _slots: Array[Marker2D] = [
	$Slots/SlotLeft,
	$Slots/SlotMiddle,
	$Slots/SlotRight,
]
@onready var _fork: Fork = $Fork
@onready var _crumbs: Node2D = $Crumbs
@onready var _teyze: Teyze = $Teyze
@onready var _challenge: HayirChallenge = $HayirChallenge
@onready var _bars: Bars = $Bars

var _foods: Array[Food] = [null, null, null]
var _busy := false
var _pending_refills: Array[int] = []
var _refill_refused := false
var _refill_generation := 0
var _won := false
var _lost := false
var _fullness := 0.0
var _mood := MOOD_START
var _win_label: Label
var _lose_label: Label


func _ready() -> void:
	randomize()
	_fork.action_finished.connect(_on_fork_finished)
	_fork.spilled.connect(_on_spilled)
	_challenge.completed.connect(_on_challenge_completed)
	_setup_labels()
	_bars.set_threshold(FULLNESS_THRESHOLD)
	_update_bars()
	for i in _slots.size():
		_spawn_food(i)


func _setup_labels() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_win_label = Label.new()
	_win_label.text = "Tabağın boş!\nHayır demeyi öğrendin!"
	_win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_label.add_theme_font_size_override("font_size", 72)
	_win_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	_win_label.position = Vector2(0, 420)
	_win_label.size = Vector2(1920, 220)
	_win_label.visible = false
	layer.add_child(_win_label)

	_lose_label = Label.new()
	_lose_label.text = "Çok şiştin!\nArtık yiyemezsin..."
	_lose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lose_label.add_theme_font_size_override("font_size", 72)
	_lose_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
	_lose_label.position = Vector2(0, 420)
	_lose_label.size = Vector2(1920, 220)
	_lose_label.visible = false
	layer.add_child(_lose_label)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_F5:
		_restart()
		return

	var slot := -1
	match key_event.keycode:
		KEY_1, KEY_KP_1:
			slot = 0
		KEY_2, KEY_KP_2:
			slot = 1
		KEY_3, KEY_KP_3:
			slot = 2

	if slot >= 0:
		_select_slot(slot)


func _select_slot(slot_index: int) -> void:
	if _busy or _lost:
		return
	var food: Food = _foods[slot_index]
	if food == null:
		return
	_busy = true
	_fork.difficulty = lerpf(1.0, 1.6, clampf((_fullness - FULLNESS_THRESHOLD) / 35.0, 0.0, 1.0))
	_fork.start_action(food, _slots[slot_index].global_position)


func _on_fork_finished(eaten: bool) -> void:
	# A bite went in (fullness + mood up), or the fork dropped (mood down).
	if eaten:
		_fullness += FULLNESS_PER_BITE
		_mood += MOOD_PER_BITE
	else:
		_mood -= MOOD_PER_DROP
	_update_bars()
	if _fullness >= 100.0:
		_lose()
		return
	# The bite action is done. If a food emptied during it, hand off to the
	# auntie's refill now (keeping the game busy); otherwise free the player —
	# except on a drop, where the auntie fetches a fresh fork first.
	if not _pending_refills.is_empty():
		_run_refill_queue()
	elif eaten:
		_busy = false
	else:
		_drop_recovery()


## After a drop: the auntie says a line, ducks off-screen to fetch a fresh fork,
## and returns. The fork itself is already parked off-screen ready to come back.
func _drop_recovery() -> void:
	var gen := _refill_generation
	_teyze.say(DROP_LINES[randi() % DROP_LINES.size()])
	await get_tree().create_timer(TALK_TIME).timeout
	if gen != _refill_generation:
		return
	_teyze.leave()
	await _teyze.left
	if gen != _refill_generation:
		return
	await get_tree().create_timer(0.5).timeout  # she's fetching a fresh fork
	if gen != _refill_generation:
		return
	_teyze.come_back()
	await _teyze.returned
	if gen != _refill_generation:
		return
	_busy = false


func _on_spilled(world_pos: Vector2, color: Color) -> void:
	_mood -= MOOD_PER_SPILL
	_update_bars()
	var crumb: Crumb = CRUMB_SCENE.instantiate()
	_crumbs.add_child(crumb)
	crumb.global_position = world_pos
	crumb.setup(color, TABLE_Y)


## Restart: reset the fork, foods and crumbs, and cancel any refill in progress.
func _restart() -> void:
	_refill_generation += 1
	_fork.reset()
	_clear_foods()
	_clear_crumbs()
	_busy = false
	_pending_refills.clear()
	_refill_refused = false
	_won = false
	_lost = false
	_fullness = 0.0
	_mood = MOOD_START
	_win_label.visible = false
	_lose_label.visible = false
	_challenge.stop()
	_teyze.reset()
	_update_bars()
	for i in _slots.size():
		_spawn_food(i)


func _clear_foods() -> void:
	for i in _foods.size():
		if _foods[i] != null:
			_foods[i].queue_free()
			_foods[i] = null


func _clear_crumbs() -> void:
	for crumb in _crumbs.get_children():
		crumb.queue_free()


func _spawn_food(slot_index: int) -> void:
	var scene: PackedScene = FOOD_SCENES[randi() % FOOD_SCENES.size()]
	var food: Food = scene.instantiate()
	_slots[slot_index].add_child(food)
	food.position = Vector2.ZERO
	food.emptied.connect(_on_food_emptied.bind(slot_index))
	_foods[slot_index] = food


func _on_food_emptied(_food: Food, slot_index: int) -> void:
	_mood += MOOD_PER_FOOD
	_update_bars()
	if _foods[slot_index] != null:
		_foods[slot_index].queue_free()
		_foods[slot_index] = null
	# Wait for the fork to finish its bite action before the auntie reacts.
	_pending_refills.append(slot_index)


## Refill slots one at a time (the teyze is a single person).
func _run_refill_queue() -> void:
	var gen := _refill_generation
	while not _pending_refills.is_empty():
		if gen != _refill_generation:
			return
		var ok: bool = await _run_refill_sequence(_pending_refills.pop_front())
		if not ok:
			return
	_busy = false
	_check_win()


## One refill: talk -> leave -> challenge -> return -> refill (or not).
func _run_refill_sequence(slot_index: int) -> bool:
	var gen := _refill_generation
	_refill_refused = false
	_teyze.say(REFILL_LINES[randi() % REFILL_LINES.size()])
	await get_tree().create_timer(TALK_TIME).timeout
	if gen != _refill_generation:
		return false
	_teyze.leave()
	await _teyze.left
	if gen != _refill_generation:
		return false
	_challenge.start()
	await get_tree().create_timer(GONE_TIME).timeout
	if gen != _refill_generation:
		return false
	_teyze.come_back()
	await _teyze.returned
	if gen != _refill_generation:
		return false
	_challenge.stop()
	if not _refill_refused:
		_spawn_food(slot_index)
	return true


func _on_challenge_completed() -> void:
	_refill_refused = true


func _check_win() -> void:
	if _won:
		return
	for food in _foods:
		if food != null:
			return
	_won = true
	_win_label.visible = true


func _update_bars() -> void:
	_fullness = clampf(_fullness, 0.0, 100.0)
	_mood = clampf(_mood, 0.0, 100.0)
	_bars.set_fullness(_fullness)
	_bars.set_mood(_mood)


func _lose() -> void:
	_lost = true
	_busy = true
	_refill_generation += 1  # cancel any in-flight refill
	_lose_label.visible = true
