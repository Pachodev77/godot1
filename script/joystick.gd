extends Control

signal joystick_updated(vector)
signal joystick_released

var is_pressed = false
var touch_id = -1
var max_distance = 50.0

onready var base = $Base
onready var stick = $Stick

var base_center = Vector2.ZERO
var last_output = Vector2.ZERO

func _ready():
	call_deferred("_initialize")

func _initialize():
	yield(get_tree(), "idle_frame")
	if not is_inside_tree():
		return
	base_center = rect_size / 2
	if stick:
		stick.rect_position = base_center - stick.rect_size / 2
	max_distance = min(rect_size.x, rect_size.y) * 0.35

func _process(delta):
	if is_pressed and max_distance > 0 and stick:
		var mouse_pos = get_global_mouse_position()
		var local_pos = mouse_pos - rect_global_position
		var offset = local_pos - base_center
		
		if offset.length() > max_distance:
			offset = offset.normalized() * max_distance
		
		stick.rect_position = base_center + offset - stick.rect_size / 2
		
		var output = offset / max_distance
		
		# Solo emitir señal si el valor cambió significativamente
		if output.distance_to(last_output) > 0.01:
			emit_signal("joystick_updated", output)
			last_output = output

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		base_center = rect_size / 2
		if stick:
			stick.rect_position = base_center - stick.rect_size / 2
		max_distance = min(rect_size.x, rect_size.y) * 0.35

func _gui_input(event):
	var event_pos = Vector2.ZERO
	var is_in_bounds = false
	
	if event is InputEventScreenTouch:
		event_pos = event.position
		is_in_bounds = Rect2(Vector2.ZERO, rect_size).has_point(event_pos)
		
		if event.pressed and touch_id == -1 and is_in_bounds:
			is_pressed = true
			touch_id = event.index
			accept_event()
		elif not event.pressed and event.index == touch_id:
			_release_joystick()
			accept_event()
	
	elif event is InputEventMouseButton:
		event_pos = event.position
		is_in_bounds = Rect2(Vector2.ZERO, rect_size).has_point(event_pos)
		
		if event.button_index == BUTTON_LEFT:
			if event.pressed and touch_id == -1 and is_in_bounds:
				is_pressed = true
				touch_id = -2
				accept_event()
			elif not event.pressed and touch_id == -2:
				_release_joystick()
				accept_event()

func _release_joystick():
	is_pressed = false
	touch_id = -1
	if stick:
		stick.rect_position = base_center - stick.rect_size / 2
	last_output = Vector2.ZERO
	emit_signal("joystick_released")
