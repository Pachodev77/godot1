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

# Camera zoom variables
var camera_zoomed_out = false
var camera_default_distance = 6.0
var camera_zoom_distance = 8.0
var zoom_speed = 10.0

func _physics_process(delta):
	# Ajustar la posición de la cámara manualmente
	if pivot and camera:
		var target_pos = Vector3(0, 2.0, camera.transform.origin.z)  # Altura reducida a 2.0
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

	$Label.text = str(forward)


	# Joystick movement
	if move_vector != Vector2.ZERO:
		direction += forward * -move_vector.y
		direction += right * move_vector.x

	direction = direction.normalized()

	# Rotar solo el modelo del personaje hacia la dirección del movimiento (no el nodo principal)
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z)
		var current_model_rotation = $"3DGodotRobot".rotation.y
		var angle_diff = fposmod(target_rotation - current_model_rotation + PI, TAU) - PI
		$"3DGodotRobot".rotation.y += angle_diff * 0.15

	#Sistema de animacion
	var horizontal_velocity = Vector2(velocidad.x, velocidad.z)
	var is_moving = horizontal_velocity.length() > 0.2
	if(not is_moving and is_on_floor()):
		anim = "Idle-loop"
	elif(is_moving and is_on_floor()):
		anim = "Run-loop"
	if(!is_on_floor()):
		anim = "Jump"

	$"3DGodotRobot/AnimationPlayer".play(anim)

	# Movimiento horizontal
	velocidad.x = direction.x * speed
	velocidad.z = direction.z * speed

	# Saltar
	if is_on_floor():
		if Input.is_action_just_pressed("tecla_salto"):
			velocidad.y = jump_velocity
	else:
		velocidad.y -= gravity * delta

	# Aplica movimiento
	move_and_slide(velocidad,Vector3.UP)

	# Verificar si el jugador está en el suelo
	on_ground = is_on_floor()

	# Joystick camera rotation (orbital)
	if camera_vector != Vector2.ZERO:
		# Rotación horizontal (alrededor del eje Y del pivot)
		pivot.rotate_y(-camera_vector.x * mouse_sensitivity * 20)
		
		# Rotación vertical (alrededor del eje X del pivot)
		camera_rotation_x -= camera_vector.y * mouse_sensitivity * 20
		camera_rotation_x = clamp(camera_rotation_x, deg2rad(max_look_down), deg2rad(max_look_up))
		pivot.rotation.x = camera_rotation_x
	
	# Camera zoom
	var target_distance = camera_zoom_distance if camera_zoomed_out else camera_default_distance
	var current_distance = $Pivot/Camera.translation.z
	var new_distance = lerp(current_distance, target_distance, zoom_speed * delta)
	$Pivot/Camera.translation.z = new_distance

export var mouse_sensitivity : float = 0.003
export var max_look_up : float = 80.0
export var max_look_down : float = -80.0

onready var pivot = $Pivot
onready var camera = $Pivot/Camera

var camera_rotation_x := 0.0

func _ready():
	# Ajustar la posición inicial de la cámara
	pivot.transform.origin.y = 2.0  # Ajustar altura del pivot
	camera.transform.origin.y = 0.0  # Asegurar que la cámara esté alineada con el pivot
	
	var move_joystick = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/MoveJoystickContainer/MoveJoystick")
	if move_joystick:
		move_joystick.connect("joystick_updated", self, "_on_MoveJoystick_updated")
		move_joystick.connect("joystick_released", self, "_on_MoveJoystick_released")

	var camera_joystick = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/CameraJoystickContainer/CameraJoystick")
	if camera_joystick:
		camera_joystick.connect("joystick_updated", self, "_on_CameraJoystick_updated")
		camera_joystick.connect("joystick_released", self, "_on_CameraJoystick_released")
	
	var zoom_button = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/CameraJoystickContainer/ButtonContainer/ZoomButton")
	if zoom_button:
		zoom_button.connect("pressed", self, "_on_ZoomButton_pressed")
	
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

func _on_JumpButton_pressed():
	if is_on_floor():
		velocidad.y = jump_velocity
