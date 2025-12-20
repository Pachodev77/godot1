extends Control

# Configuración del Crosshair
export var max_track_distance : float = 50.0  # Distancia máxima para rastrear
export var smooth_speed : float = 15.0        # Velocidad de suavizado del movimiento
export var crosshair_size : float = 24.0      # Tamaño general
export var circle_radius : float = 8.0        # Radio del círculo
export var cross_gap : float = 4.0            # Espacio en el centro de la cruz
export var cross_length : float = 6.0         # Largo de las líneas de la cruz
export var line_thickness : float = 2.0       # Grosor de las líneas

var current_target : Spatial = null
var current_target_3d_pos : Vector3 = Vector3.ZERO
onready var camera = get_viewport().get_camera()
var current_pulse : float = 1.0

func _ready():
	rect_size = Vector2(crosshair_size, crosshair_size)
	rect_pivot_offset = rect_size / 2
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE

func _draw():
	var center = rect_size / 2
	var red = Color.red
	
	# Dibujar círculo (contorno)
	draw_arc(center, circle_radius, 0, TAU, 32, red, line_thickness, true)
	
	# Dibujar la cruz "rota" (que no se junta en el centro)
	# Línea Arriba
	draw_line(center + Vector2(0, -cross_gap), center + Vector2(0, -(cross_gap + cross_length)), red, line_thickness)
	# Línea Abajo
	draw_line(center + Vector2(0, cross_gap), center + Vector2(0, cross_gap + cross_length), red, line_thickness)
	# Línea Izquierda
	draw_line(center + Vector2(-cross_gap, 0), center + Vector2(-(cross_gap + cross_length), 0), red, line_thickness)
	# Línea Derecha
	draw_line(center + Vector2(cross_gap, 0), center + Vector2(cross_gap + cross_length, 0), red, line_thickness)

func _process(delta):
	if !camera:
		camera = get_viewport().get_camera()
		if !camera: return

	_find_nearest_enemy()
	
	if current_target and is_instance_valid(current_target):
		var target_pos = current_target.global_transform.origin
		
		# Centrar usando el AABB del MeshInstance
		if current_target.has_node("MeshInstance"):
			var m = current_target.get_node("MeshInstance")
			if m is MeshInstance:
				target_pos = m.global_transform.xform(m.get_aabb().get_center())
		else:
			target_pos.y += 1.0 
		
		current_target_3d_pos = target_pos
		
		var cam_forward = -camera.global_transform.basis.z
		var to_target = (target_pos - camera.global_transform.origin).normalized()
		
		# Solo ocultar si está COMPLETAMENTE detrás de la cámara (ángulo > 90 grados)
		if cam_forward.dot(to_target) < 0:
			visible = false
		else:
			var screen_pos = camera.unproject_position(target_pos)
			
			# Verificar si está dentro de los límites de la pantalla (con un margen)
			var screen_size = get_viewport().get_visible_rect().size
			if screen_pos.x < -100 or screen_pos.x > screen_size.x + 100 or screen_pos.y < -100 or screen_pos.y > screen_size.y + 100:
				visible = false
			else:
				var desired_pos = screen_pos - (rect_size / 2)
				if !visible:
					rect_position = desired_pos
					visible = true
				else:
					rect_position = rect_position.linear_interpolate(desired_pos, smooth_speed * delta)
				
			# Efecto de escala pulsante
			current_pulse = 1.0 + sin(OS.get_ticks_msec() * 0.01) * 0.1
			rect_scale = Vector2(current_pulse, current_pulse)
			update() # Forzar redibujado para el pulso si fuera necesario (aunque scale ya lo hace)
	else:
		visible = false

func _find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemigos")
	var nearest_enemy = null
	var min_dist = max_track_distance
	
	var player = null
	var players = get_tree().get_nodes_in_group("jugador")
	if players.size() > 0:
		player = players[0]
	
	if !player: return

	for enemy in enemies:
		if !enemy is Spatial: continue
		
		var dist = player.global_transform.origin.distance_to(enemy.global_transform.origin)
		if dist < min_dist:
			# Verificar si está en la "vista" aproximada de la cámara (dentro del frustum)
			var target_pos = enemy.global_transform.origin
			if !camera.is_position_behind(target_pos):
				min_dist = dist
				nearest_enemy = enemy
	
	current_target = nearest_enemy
