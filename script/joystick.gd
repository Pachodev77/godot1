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

func _update_from_local(local_pos):
    var offset = local_pos - base_center
    if offset.length() > max_distance:
        offset = offset.normalized() * max_distance
    if stick:
        stick.rect_position = base_center + offset - stick.rect_size / 2
    var output = offset / max_distance
    if output.distance_to(last_output) > 0.01:
        emit_signal("joystick_updated", output)
        last_output = output

func _notification(what):
    if what == NOTIFICATION_RESIZED:
        base_center = rect_size / 2
        if stick:
            stick.rect_position = base_center - stick.rect_size / 2
        max_distance = min(rect_size.x, rect_size.y) * 0.35

func _input(event):
    if event is InputEventScreenTouch:
        var global_rect = get_global_rect()
        var in_bounds = global_rect.has_point(event.position)
        var local = event.position - global_rect.position
        if event.pressed and touch_id == -1 and in_bounds:
            is_pressed = true
            touch_id = event.index
            _update_from_local(local)
        elif not event.pressed and event.index == touch_id:
            _release_joystick()
    elif event is InputEventScreenDrag:
        if event.index == touch_id and is_pressed:
            var global_rect = get_global_rect()
            var local = event.position - global_rect.position
            _update_from_local(local)
    elif event is InputEventMouseButton:
        var local = event.position
        var in_bounds = Rect2(Vector2.ZERO, rect_size).has_point(local)
        if event.button_index == BUTTON_LEFT:
            if event.pressed and touch_id == -1 and in_bounds:
                is_pressed = true
                touch_id = -2
                _update_from_local(local)
            elif not event.pressed and touch_id == -2:
                _release_joystick()
    elif event is InputEventMouseMotion:
        if is_pressed and touch_id == -2:
            var local = event.position
            _update_from_local(local)

func _release_joystick():
	is_pressed = false
	touch_id = -1
	if stick:
		stick.rect_position = base_center - stick.rect_size / 2
	last_output = Vector2.ZERO
	emit_signal("joystick_released")
