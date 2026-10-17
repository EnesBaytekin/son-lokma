class_name BalanceChallenge
extends Challenge
## "Denge" challenge: a needle slides left or right along the bar; press A/D to
## flip its direction and keep it inside the green safe zone in the middle.
## Outside the zone, the fork spills crumbs.

const NEEDLE_SPEED := 0.7      # bar-width fraction per second (scaled by difficulty)
const ZONE_HALF := 0.15        # safe zone half-width, as a bar fraction

var _needle: float = 0.0       # -1..1 across the bar
var _dir: int = 1              # +1 right, -1 left
var _spill_timer: float = 0.0

var _zone: ColorRect           # green safe zone
var _cursor: ColorRect         # the sliding needle


func start(in_fork: Fork, in_difficulty: float) -> void:
	super.start(in_fork, in_difficulty)
	_needle = 0.0
	_dir = 1 if randf() < 0.5 else -1
	_spill_timer = 0.0
	_set_hint("A ve D ile imleci yeşil alanda tut!")
	_show_key("A / D", BAR_YELLOW)
	_build_balance_ui()
	_update()


func tick(delta: float) -> void:
	_needle = clampf(_needle + _dir * NEEDLE_SPEED * difficulty * delta, -1.0, 1.0)
	if absf(_needle) > ZONE_HALF:
		_spill_timer -= delta
		if _spill_timer <= 0.0:
			_spill_timer = 0.35 / difficulty
			fork.spill()
	_update()


func _build_balance_ui() -> void:
	if _zone != null:
		return
	# The cursor's pixel half-range across the bar (matches `_update`).
	var half_range := _bar_w * 0.5 - 2.0
	_zone = ColorRect.new()
	_zone.color = Color(0.2, 0.8, 0.3)
	_zone.size = Vector2(half_range * 2.0 * ZONE_HALF, 30.0)
	_zone.position = _bar_bg.position + Vector2(_bar_w * 0.5 - _zone.size.x * 0.5, 3.0)
	_root.add_child(_zone)

	_cursor = ColorRect.new()
	_cursor.color = Color.WHITE
	_cursor.size = Vector2(4.0, 30.0)
	_cursor.position = Vector2(_bar_bg.position.x + _bar_w * 0.5 - 2.0, _bar_bg.position.y + 3.0)
	_root.add_child(_cursor)


func _update() -> void:
	var inside := absf(_needle) <= ZONE_HALF
	_cursor.color = Color.WHITE if inside else BAR_RED
	_cursor.position.x = _bar_bg.position.x + _bar_w * 0.5 - 2.0 + _needle * (_bar_w * 0.5 - 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kc := (event as InputEventKey).keycode
		if kc == KEY_A:
			get_viewport().set_input_as_handled()
			_dir = -1
		elif kc == KEY_D:
			get_viewport().set_input_as_handled()
			_dir = 1
