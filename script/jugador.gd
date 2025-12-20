extends KinematicBody

#--- Movement Settings ---
var velocidad = Vector3()
export var speed : float = 6.0

export var sprint_speed : float = 12.0
export var jetpack_speed : float = 8.0
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
var is_attacking = false
var is_sprinting = false
var is_jetpacking = false
var is_jumping = false

# Camera zoom variables
var camera_mode = 0 # 0: Default, 1: Zoomed Out, 2: First Person
var camera_default_distance = 3.5
var camera_zoom_distance = 5.5
var camera_first_person_distance = 0.0
var zoom_speed = 10.0
export var camera_near_min : float = 0.5
export var camera_near_max : float = 1.5

func _physics_process(delta):
	# Laser visual timer
	if laser_timer > 0:
		laser_timer -= delta
		if laser_timer <= 0:
			if laser_geom:
				laser_geom.clear()
	
	# Laser audio timer (solo 1 segundo)
	if laser_audio_timer > 0:
		laser_audio_timer -= delta
		if laser_audio_timer <= 0:
			if laser_sound_player:
				laser_sound_player.stop()
	
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
	var current_speed = speed
	if is_sprinting:
		current_speed = sprint_speed
	
	velocidad.x = direction.x * current_speed
	velocidad.z = direction.z * current_speed

	# Gravedad y Salto
	if is_jetpacking:
		velocidad.y = jetpack_speed
	else:
		velocidad.y -= gravity * delta
	
	var snap = Vector3.DOWN
	if is_jetpacking:
		snap = Vector3.ZERO
		is_jumping = false
	elif is_on_floor():
		is_jumping = false
		if jump_requested or Input.is_action_just_pressed("tecla_salto"):
			velocidad.y = jump_velocity
			snap = Vector3.ZERO
			is_jumping = true
			if jump_sound_player:
				jump_sound_player.stop()
				jump_sound_player.play(0.5)
	
	jump_requested = false
	
	# Aplica movimiento con snap para evitar rebotes en pendientes
	velocidad = move_and_slide_with_snap(velocidad, snap, Vector3.UP, true)

	# Verificar si el jugador está en el suelo
	on_ground = is_on_floor()

	#Sistema de animacion (Actualizado despues del movimiento)
	var horizontal_velocity = Vector2(velocidad.x, velocidad.z)
	var is_moving = horizontal_velocity.length() > 0.2
	
	if is_attacking:
		anim = "Attack"
	elif is_jetpacking:
		anim = "Idle-loop"
	elif on_ground:
		if is_moving:
			if is_sprinting:
				# Use existing Run loop but maybe faster if we had separate animation
				anim = "Run-loop"
				animation_player.playback_speed = 1.5
			else:
				anim = "Run-loop"
				animation_player.playback_speed = 1.0
		else:
			anim = "Idle-loop"
			animation_player.playback_speed = 1.0
	else:
		if is_jumping and velocidad.y > 0:
			anim = "Jump"
		else:
			anim = "Idle-loop"
			animation_player.playback_speed = 1.0

	# Solo cambiar animación si es diferente
	if animation_player.current_animation != anim:
		animation_player.play(anim)

	if camera_vector != Vector2.ZERO:
		# Rotación horizontal (alrededor del eje Y del pivot)
		pivot.rotate_y(-camera_vector.x * mouse_sensitivity * 12)
		
		# Rotación vertical (alrededor del eje X del pivot)
		var invert_factor = 1.0
		if camera_mode == 2:
			invert_factor = -1.0 # Invertir en primera persona (Arriba mira abajo)
			
		camera_rotation_x += camera_vector.y * mouse_sensitivity * 6 * invert_factor
		
		# Definir límites dinámicos según el modo de cámara
		var current_limit_up = max_look_up
		var current_limit_down = max_look_down
		
		if camera_mode == 2: # Primera persona: Libertad casi total
			current_limit_up = 89.0
			current_limit_down = -89.0
			
		camera_rotation_x = clamp(camera_rotation_x, deg2rad(current_limit_down), deg2rad(current_limit_up))
		pivot.rotation.x = camera_rotation_x
	
	# Camera zoom (solo actualizar si hay diferencia)
	var target_distance = camera_default_distance
	if camera_mode == 1:
		target_distance = camera_zoom_distance
	elif camera_mode == 2:
		target_distance = camera_first_person_distance

	var current_distance = camera.translation.z
	if abs(current_distance - target_distance) > 0.01:
		var new_distance = lerp(current_distance, target_distance, zoom_speed * delta)
		camera.translation.z = new_distance
	else:
		camera.translation.z = target_distance
	
	# Gestionar visibilidad del robot en primera persona
	if camera_mode == 2:
		if robot_model.visible:
			robot_model.visible = false
	else:
		if !robot_model.visible:
			robot_model.visible = true

	var desired_near = camera_near_max
	if camera_rotation_x < 0.0:
		desired_near = camera_near_min
	camera.near = lerp(camera.near, desired_near, 5.0 * delta)

	# Optimización: Culling solo cada 0.1 segundos en lugar de cada frame
	cull_timer += delta
	if cull_timer >= cull_update_interval:
		var player_pos = global_transform.origin  # Cachear posición del jugador
		for n in cull_targets:
			if n:
				var d = n.translation.distance_to(player_pos)  # Usar translation en lugar de global_transform
				if n.visible:
					if d > cull_far:
						n.visible = false
				else:
					if d < cull_near:
						n.visible = true
		cull_timer = 0.0

	# Optimización: Actualizar FPS solo cada 0.5 segundos
	fps_update_timer += delta
	if fps_update_timer >= fps_update_interval:
		if fps_label_node:
			fps_label_node.text = "FPS: " + str(Engine.get_frames_per_second())
		fps_update_timer = 0.0

export var mouse_sensitivity : float = 0.003
export var max_look_up : float = 5.0
export var max_look_down : float = -45.0
export var cull_near : float = 220.0
export var cull_far : float = 260.0

# Timers para optimización
var cull_timer : float = 0.0
var cull_update_interval : float = 0.1  # Actualizar culling cada 0.1s
var fps_update_timer : float = 0.0
var fps_update_interval : float = 0.5  # Actualizar FPS cada 0.5s

onready var pivot = $Pivot
onready var camera = $Pivot/Camera
onready var flashlight = $"Pivot/SpotLight"
onready var robot_model = $"RobotProcedural"
onready var animation_player = $"RobotProcedural/AnimationPlayer"

var camera_rotation_x := 0.0

# Referencias UI para multitouch
onready var move_joystick_node = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/MoveJoystickContainer/MoveJoystick")
onready var camera_joystick_node = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/CameraJoystickContainer/CameraJoystick")
onready var zoom_button_node = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/MoveJoystickContainer/ButtonContainer/ZoomButton")
onready var flashlight_button_node = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/MoveJoystickContainer/ButtonContainer/FlashlightButton")
onready var jump_button_node = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/CameraJoystickContainer/ButtonContainer/JumpButton")
onready var action_button_node = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/CameraJoystickContainer/ButtonContainer/ActionButton")
onready var r1_button_node = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/StackExtraR/ExtraBtnR1")
onready var r3_button_node = get_node_or_null("/root/Escena/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/StackExtraR/ExtraBtnR3")
onready var crosshair_node = get_node_or_null("/root/Escena/CanvasLayer/AutoCrosshair")

var laser_geom : ImmediateGeometry = null
var laser_material : SpatialMaterial = null
var laser_timer : float = 0.0
var laser_audio_timer : float = 0.0
var fps_label_node = null
onready var cull_targets = [
	get_node_or_null("/root/Escena/Forest"),
	get_node_or_null("/root/Escena/Forest2"),
	get_node_or_null("/root/Escena/Forest3"),
	get_node_or_null("/root/Escena/Forest4")
]

func _ready():
	add_to_group("jugador")
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

	if action_button_node:
		action_button_node.connect("pressed", self, "_on_ActionButton_pressed")

	if r3_button_node:
		r3_button_node.connect("button_down", self, "_on_R3Button_down")
		r3_button_node.connect("button_up", self, "_on_R3Button_up")

	if r1_button_node:
		r1_button_node.connect("button_down", self, "_on_R1Button_down")
		r1_button_node.connect("button_up", self, "_on_R1Button_up")

	# Setup Laser
	laser_geom = ImmediateGeometry.new()
	add_child(laser_geom)
	laser_geom.set_as_toplevel(true)
	laser_geom.global_transform = Transform.IDENTITY
	
	laser_material = SpatialMaterial.new()
	laser_material.flags_unshaded = true
	laser_material.flags_no_depth_test = false # Respetar profundidad (no atravesar avatar)
	laser_material.albedo_color = Color(1, 0, 0, 1) # Rojo puro
	laser_geom.material_override = laser_material
	
	animation_player.connect("animation_finished", self, "_on_animation_finished")

	fps_label_node = get_node_or_null("/root/Escena/CanvasLayer/FPSLabel")
	if fps_label_node == null:
		fps_label_node = get_node_or_null("/root/Escena/ControlUI/FPSLabel")
	
	_setup_audio()

var ambient_player : AudioStreamPlayer
var jump_sound_player : AudioStreamPlayer
var laser_sound_player : AudioStreamPlayer
var jetpack_sound_player : AudioStreamPlayer

func _setup_audio():
	# Música de ambiente
	ambient_player = AudioStreamPlayer.new()
	var ambient_stream = load("res://sounds/Ambient.mp3")
	if ambient_stream is AudioStreamMP3:
		ambient_stream.loop = true
	ambient_player.stream = ambient_stream
	ambient_player.autoplay = true
	ambient_player.bus = "Master"
	add_child(ambient_player)
	
	# Jump
	jump_sound_player = AudioStreamPlayer.new()
	var jump_stream = load("res://sounds/Jump.mp3")
	if jump_stream is AudioStreamMP3:
		jump_stream.loop = false
	jump_sound_player.stream = jump_stream
	add_child(jump_sound_player)
	
	# Laser
	laser_sound_player = AudioStreamPlayer.new()
	var laser_stream = load("res://sounds/Laser.mp3")
	if laser_stream is AudioStreamMP3:
		laser_stream.loop = false
	laser_sound_player.stream = laser_stream
	add_child(laser_sound_player)
	
	# Jetpack
	jetpack_sound_player = AudioStreamPlayer.new()
	var jetpack_stream = load("res://sounds/Jetpack.mp3")
	if jetpack_stream is AudioStreamMP3:
		jetpack_stream.loop = true
	jetpack_sound_player.stream = jetpack_stream
	add_child(jetpack_sound_player)
	
	# Iniciar ambiente si no suena por autoplay
	if !ambient_player.playing:
		ambient_player.play()
	
	# ELIMINADO: Conexiones duplicadas de botones (ya se conectan en líneas 174-181)


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
	camera_mode += 1
	if camera_mode > 2:
		camera_mode = 0
	
	# Si volvemos a modo normal/zoom (no FP), asegurar que la rotación respete los límites
	if camera_mode != 2:
		camera_rotation_x = clamp(camera_rotation_x, deg2rad(max_look_down), deg2rad(max_look_up))
		pivot.rotation.x = camera_rotation_x

func _on_FlashlightButton_pressed():
	if flashlight:
		flashlight.visible = !flashlight.visible

func _on_JumpButton_pressed():
	jump_requested = true

func _on_ActionButton_pressed():
	if !is_attacking:
		is_attacking = true
		animation_player.play("Attack")
		_fire_laser()

func _fire_laser():
	if !laser_geom: return
	
	if laser_sound_player:
		laser_sound_player.stop()
		laser_sound_player.play()
		laser_audio_timer = 1.5 # Limitar a 1.5 segundos
	
	var start_pos = _get_hand_pos()
	var end_pos = Vector3.ZERO
	
	if crosshair_node and crosshair_node.current_target and is_instance_valid(crosshair_node.current_target):
		end_pos = crosshair_node.current_target_3d_pos
	else:
		var forward = -camera.global_transform.basis.z.normalized()
		end_pos = start_pos + (forward * 50.0)
	
	# Offset para que no empiece DENTRO de la mano y se oculte por el mesh del brazo
	var shot_dir = (end_pos - start_pos).normalized()
	start_pos += shot_dir * 0.2
	
	# Dibujar el rayo
	laser_geom.clear()
	laser_geom.begin(Mesh.PRIMITIVE_LINES)
	laser_geom.add_vertex(start_pos)
	laser_geom.add_vertex(end_pos)
	laser_geom.end()
	
	laser_timer = 0.1 # Duración del destello
	
	# Detección de impacto (Raycast manual)
	var space_state = get_world().direct_space_state
	# Excluir al propio jugador del raycast
	var result = space_state.intersect_ray(start_pos, end_pos, [self])
	
	if result:
		var hit_collider = result.collider
		if hit_collider and hit_collider.is_in_group("enemigos"):
			if hit_collider.has_method("flash_hit"):
				hit_collider.flash_hit()

func _get_hand_pos() -> Vector3:
	if robot_model:
		var skeleton = robot_model.get_node_or_null("Skeleton")
		if skeleton:
			var hand = skeleton.get_node_or_null("RightHand")
			if hand:
				# Forzar actualización si es necesario
				return hand.global_transform.origin
	
	# Fallback si no se encuentra la mano
	return global_transform.origin + Vector3.UP * 1.5

func _on_R3Button_down():
	is_sprinting = true

func _on_R3Button_up():
	is_sprinting = false

func _on_R1Button_down():
	is_jetpacking = true
	if jetpack_sound_player:
		jetpack_sound_player.play()
	if robot_model.has_method("set_jetpack_emission"):
		robot_model.set_jetpack_emission(true)

func _on_R1Button_up():
	is_jetpacking = false
	if jetpack_sound_player:
		jetpack_sound_player.stop()
	if robot_model.has_method("set_jetpack_emission"):
		robot_model.set_jetpack_emission(false)

func _on_animation_finished(anim_name):
	if anim_name == "Attack":
		is_attacking = false
		animation_player.playback_speed = 1.0

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
				if action_button_node and action_button_node.get_global_rect().has_point(pos):
					_on_ActionButton_pressed()
				if r1_button_node and r1_button_node.get_global_rect().has_point(pos):
					_on_R1Button_down()
				if r3_button_node and r3_button_node.get_global_rect().has_point(pos):
					_on_R3Button_down()
				if zoom_button_node and zoom_button_node.get_global_rect().has_point(pos):
					_on_ZoomButton_pressed()
				if flashlight_button_node and flashlight_button_node.get_global_rect().has_point(pos):
					_on_FlashlightButton_pressed()
			elif !event.pressed:
				# Check releases for buttons that need hold interaction
				if r3_button_node and r3_button_node.get_global_rect().has_point(pos):
					_on_R3Button_up()
				if r1_button_node and r1_button_node.get_global_rect().has_point(pos):
					_on_R1Button_up()
