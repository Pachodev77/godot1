extends Control

signal joystick_updated(vector)
signal joystick_released

var is_pressed = false
var touch_id = -1
var max_distance = 50.0

onready var base = $Base
onready var stick = $Stick

var base_center = Vector2.ZERO

func _ready():
	base_center = rect_size / 2
	stick.rect_position = base_center - stick.rect_size / 2

func _process(delta):
	if is_pressed:
		var mouse_pos = get_global_mouse_position()
		var local_pos = mouse_pos - rect_global_position
		var offset = local_pos - base_center
		
		if offset.length() > max_distance:
			offset = offset.normalized() * max_distance
		
		stick.rect_position = base_center + offset - stick.rect_size / 2
		
		var output = offset / max_distance
		emit_signal("joystick_updated", output)

func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			is_pressed = true
			touch_id = event.index
		elif not event.pressed and event.index == touch_id:
			_release_joystick()
	
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed and touch_id == -1:
				is_pressed = true
				touch_id = -2
			elif not event.pressed and touch_id == -2:
				_release_joystick()

func _release_joystick():
	is_pressed = false
	touch_id = -1
	stick.rect_position = base_center - stick.rect_size / 2
	emit_signal("joystick_released")
