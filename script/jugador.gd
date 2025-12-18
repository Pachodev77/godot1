extends KinematicBody

#--- Movement Settings ---
var velocidad = Vector3()
export var speed : float = 6.0
export var jump_velocity : float = 4.5
var gravity = 20.0  # Gravedad

var anim = ""
var on_ground = false

#variable para determinar si cae
var altura = 0

# Joystick variables
var move_vector = Vector2.ZERO
var camera_vector = Vector2.ZERO
var jump_requested = false

# Camera zoom variables
var camera_zoomed_out = false
var camera_default_distance = 6.0
var camera_zoom_distance = 8.0
var zoom_speed = 10.0

func _physics_process(delta):
	# Ajustar la posición de la cámara manualmente (solo si es necesario)
	if abs(camera.transform.origin.y - 2.0) > 0.01:
		var target_pos = Vector3(0, 2.0, camera.transform.origin.z)
		camera.transform.origin = camera.transform.origin.linear_interpolate(target_pos, 10.0 * delta)
		
	var direction = Vector3.ZERO

	# Obtener la dirección basada en la rotación de la cámara (orbital)
	var camera_basis = pivot.global_transform.basis
	var forward = -camera_basis.z
	var right = camera_basis.x
	
	# Proyectar forward y right en el plano horizontal (ignorar componente Y)
	forward.y = 0
	forward = forward.normalized()
	right.y = 0
	right = right.normalized()

	# Joystick movement
	if move_vector != Vector2.ZERO:
		direction += forward * -move_vector.y
		direction += right * move_vector.x

	direction = direction.normalized()

	# Rotar solo el modelo del personaje hacia la dirección del movimiento (no el nodo principal)
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z)
		var current_model_rotation = robot_model.rotation.y
		var angle_diff = fposmod(target_rotation - current_model_rotation + PI, TAU) - PI
		robot_model.rotation.y += angle_diff * 0.15

	# Movimiento horizontal
	velocidad.x = direction.x * speed
	velocidad.z = direction.z * speed

	# Gravedad y Salto
	velocidad.y -= gravity * delta
	
	var snap = Vector3.DOWN
	if is_on_floor():
		if jump_requested or Input.is_action_just_pressed("tecla_salto"):
			velocidad.y = jump_velocity
			snap = Vector3.ZERO
	
	jump_requested = false
	
	# Aplica movimiento con snap para evitar rebotes en pendientes
	velocidad = move_and_slide_with_snap(velocidad, snap, Vector3.UP, true)

	# Verificar si el jugador está en el suelo
	on_ground = is_on_floor()

	#Sistema de animacion (Actualizado despues del movimiento)
	var horizontal_velocity = Vector2(velocidad.x, velocidad.z)
	var is_moving = horizontal_velocity.length() > 0.2
	
	if on_ground:
		if is_moving:
			anim = "Run-loop"
		else:
			anim = "Idle-loop"
	else:
		anim = "Jump"

	# Solo cambiar animación si es diferente
	if animation_player.current_animation != anim:
		animation_player.play(anim)

	# Joystick camera rotation (orbital)
	if camera_vector != Vector2.ZERO:
		# Rotación horizontal (alrededor del eje Y del pivot)
		pivot.rotate_y(-camera_vector.x * mouse_sensitivity * 20)
		
		# Rotación vertical (alrededor del eje X del pivot)
		camera_rotation_x += camera_vector.y * mouse_sensitivity * 10
		camera_rotation_x = clamp(camera_rotation_x, deg2rad(max_look_down), deg2rad(max_look_up))
		pivot.rotation.x = camera_rotation_x
	
	# Camera zoom (solo actualizar si hay diferencia)
	var target_distance = camera_zoom_distance if camera_zoomed_out else camera_default_distance
	var current_distance = camera.translation.z
	if abs(current_distance - target_distance) > 0.01:
		var new_distance = lerp(current_distance, target_distance, zoom_speed * delta)
		camera.translation.z = new_distance

	for n in cull_targets:
		if n:
			var d = n.global_transform.origin.distance_to(global_transform.origin)
			if n.visible:
				if d > cull_far:
					n.visible = false
			else:
				if d < cull_near:
					n.visible = true

	if fps_label_node:
		fps_label_node.text = "FPS: " + str(Engine.get_frames_per_second())

export var mouse_sensitivity : float = 0.003
export var max_look_up : float = 25.0
export var max_look_down : float = -30.0
export var cull_near : float = 220.0
export var cull_far : float = 260.0

onready var pivot = $Pivot
onready var camera = $Pivot/Camera
onready var flashlight = $"3DGodotRobot/SpotLight"
onready var robot_model = $"3DGodotRobot"
onready var animation_player = $"3DGodotRobot/AnimationPlayer"

var camera_rotation_x := 0.0

# Referencias UI para multitouch
onready var move_joystick_node = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/MoveJoystickContainer/MoveJoystick")
onready var camera_joystick_node = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/CameraJoystickContainer/CameraJoystick")
onready var zoom_button_node = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/CameraJoystickContainer/ButtonContainer/ZoomButton")
onready var flashlight_button_node = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/CameraJoystickContainer/ButtonContainer/FlashlightButton")
onready var jump_button_node = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/JumpButtonContainer/JumpButton")
var fps_label_node = null
onready var cull_targets = [
    get_node_or_null("/root/Escena/Forest"),
    get_node_or_null("/root/Escena/Forest2"),
    get_node_or_null("/root/Escena/Forest3"),
    get_node_or_null("/root/Escena/Forest4")
]

func _ready():
	# Ajustar la posición inicial de la cámara
	pivot.transform.origin.y = 2.0  # Ajustar altura del pivot
	camera.transform.origin.y = 0.0  # Asegurar que la cámara esté alineada con el pivot
	
	if move_joystick_node:
		move_joystick_node.connect("joystick_updated", self, "_on_MoveJoystick_updated")
		move_joystick_node.connect("joystick_released", self, "_on_MoveJoystick_released")

	if camera_joystick_node:
		camera_joystick_node.connect("joystick_updated", self, "_on_CameraJoystick_updated")
		camera_joystick_node.connect("joystick_released", self, "_on_CameraJoystick_released")

	if zoom_button_node:
		zoom_button_node.connect("pressed", self, "_on_ZoomButton_pressed")

	if flashlight_button_node:
		flashlight_button_node.connect("pressed", self, "_on_FlashlightButton_pressed")

	if jump_button_node:
		jump_button_node.connect("pressed", self, "_on_JumpButton_pressed")

	fps_label_node = get_node_or_null("/root/Escena/CanvasLayer/FPSLabel")
	if fps_label_node == null:
		fps_label_node = get_node_or_null("/root/Escena/ControlUI/FPSLabel")
	
	var zoom_button = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/CameraJoystickContainer/ButtonContainer/ZoomButton")
	if zoom_button:
		zoom_button.connect("pressed", self, "_on_ZoomButton_pressed")

	var flashlight_button = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/CameraJoystickContainer/ButtonContainer/FlashlightButton")
	if flashlight_button:
		flashlight_button.connect("pressed", self, "_on_FlashlightButton_pressed")
	
	var jump_button = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/JumpButtonContainer/JumpButton")
	if jump_button:
		jump_button.connect("pressed", self, "_on_JumpButton_pressed")


# Joystick signal handlers
func _on_MoveJoystick_updated(vector):
	move_vector = vector

func _on_MoveJoystick_released():
	move_vector = Vector2.ZERO

func _on_CameraJoystick_updated(vector):
	camera_vector = vector

func _on_CameraJoystick_released():
	camera_vector = Vector2.ZERO

func _on_ZoomButton_pressed():
    camera_zoomed_out = !camera_zoomed_out

func _on_FlashlightButton_pressed():
    if flashlight:
        flashlight.visible = !flashlight.visible

func _on_JumpButton_pressed():
    jump_requested = true

func _input(event):
    if event is InputEventScreenTouch:
        var joystick_active = false
        if move_joystick_node and move_joystick_node.touch_id != -1:
            joystick_active = true
        if camera_joystick_node and camera_joystick_node.touch_id != -1:
            joystick_active = true
        if joystick_active:
            var pos = event.position
            if event.pressed:
                if jump_button_node and jump_button_node.get_global_rect().has_point(pos):
                    _on_JumpButton_pressed()
                if zoom_button_node and zoom_button_node.get_global_rect().has_point(pos):
                    _on_ZoomButton_pressed()
                if flashlight_button_node and flashlight_button_node.get_global_rect().has_point(pos):
                    _on_FlashlightButton_pressed()
