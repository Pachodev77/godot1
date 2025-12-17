extends Control

var touch_id = -1
var direction = Vector2.ZERO
var radius = 0.0

onready var base = $Base
onready var stick = $Stick
onready var center = Vector2.ZERO

func _ready():
	center = base.get_global_rect().position + base.get_global_rect().size / 2
	radius = base.get_global_rect().size.x / 2

	stick.rect_global_position = center - stick.rect_size / 2

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			if base.get_global_rect().has_point(event.position):
				touch_id = event.index
				_update_stick(event.position)

		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			direction = Vector2.ZERO
			stick.rect_global_position = center - stick.rect_size / 2

	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			_update_stick(event.position)

func _update_stick(pos):
	var offset = pos - center
	offset = offset.clamped(radius)

	stick.rect_global_position = center + offset - stick.rect_size / 2
	direction = offset / radius

