extends Spatial

# Configuración
export var num_crystals : int = 50
# El mapa es un grid de 2x2 tiles de 155x155 cada uno
# Rango total aproximado: 0 a 310 en ambos ejes
export var map_min_x : float = 10.0
export var map_max_x : float = 300.0
export var map_min_z : float = 10.0
export var map_max_z : float = 300.0

export var spawn_height : float = 1.5
export var min_distance_between_crystals : float = 5.0

# Escena del cristal
var crystal_scene = preload("res://escena/cristal.tscn")

# Estadísticas
var total_crystals : int = 0
var collected_crystals : int = 0

# Referencias UI
var crystal_label = null

func _ready():
	# Buscar el label de cristales en la UI
	crystal_label = get_node_or_null("/root/Escena/CanvasLayer/CrystalLabel")
	
	# Si no existe, crear la estructura de la UI (Icono 3D + Contador)
	if crystal_label == null:
		var canvas_layer = get_node_or_null("/root/Escena/CanvasLayer")
		if canvas_layer:
			# Contenedor principal
			var hbox = HBoxContainer.new()
			hbox.name = "CrystalUI"
			hbox.rect_position = Vector2(25, 25)
			hbox.set("custom_constants/separation", 10)
			canvas_layer.add_child(hbox)
			
			# Contenedor del icono (Usamos TextureRect para mejor soporte de transparencia)
			var icon_texture_rect = TextureRect.new()
			icon_texture_rect.rect_min_size = Vector2(80, 80)
			icon_texture_rect.expand = true
			icon_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hbox.add_child(icon_texture_rect)
			
			# Viewport aislado
			var viewport = Viewport.new()
			viewport.size = Vector2(256, 256)
			viewport.transparent_bg = true
			viewport.own_world = true # Aislar del mundo principal (sin niebla/luces externas)
			viewport.usage = Viewport.USAGE_3D
			viewport.render_target_v_flip = true
			viewport.msaa = Viewport.MSAA_4X
			viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
			add_child(viewport) # Añadir como hijo del manager, no en la UI directamente
			
			# Asignar la textura del viewport al rect
			icon_texture_rect.texture = viewport.get_texture()
			
			# Escena 3D dentro del icono
			var spatial = Spatial.new()
			viewport.add_child(spatial)
			
			var camera = Camera.new()
			camera.translation = Vector3(0, 0, 1.2)
			camera.current = true
			spatial.add_child(camera)
			
			var crystal_icon = crystal_scene.instance()
			crystal_icon.translation = Vector3(0, 0, 0)
			crystal_icon.scale = Vector3(1.2, 1.2, 1.2)
			crystal_icon.is_ui_icon = true
			
			if crystal_icon.has_node("CollisionShape"):
				crystal_icon.get_node("CollisionShape").queue_free()
			spatial.add_child(crystal_icon)
			
			# Luz dedicada para el icono
			var light = OmniLight.new()
			light.translation = Vector3(1, 1, 1)
			light.light_energy = 2.0
			spatial.add_child(light)
			
			var light2 = OmniLight.new()
			light2.translation = Vector3(-1, -1, 1)
			light2.light_energy = 1.0
			spatial.add_child(light2)
			
			# Label para el contador con fondo negro
			crystal_label = Label.new()
			crystal_label.name = "CrystalLabel"
			crystal_label.rect_scale = Vector2(2.2, 2.2)
			crystal_label.add_color_override("font_color", Color(0.9, 0.7, 1.0, 1.0)) # Púrpura más claro para contraste
			
			var bg_style = StyleBoxFlat.new()
			bg_style.bg_color = Color(0, 0, 0, 0.7) # Negro semi-transparente para que no sea muy brusco
			bg_style.set_corner_radius_all(5)
			bg_style.content_margin_left = 10
			bg_style.content_margin_right = 10
			bg_style.content_margin_top = 2
			bg_style.content_margin_bottom = 2
			crystal_label.add_stylebox_override("normal", bg_style)
			
			hbox.add_child(crystal_label)
			
			# Hacer que el cristal del icono gire
			var anim_timer = Timer.new()
			anim_timer.wait_time = 0.016 # ~60fps
			anim_timer.autostart = true
			anim_timer.connect("timeout", self, "_animate_icon", [crystal_icon])
			add_child(anim_timer)
	
	# Generar cristales
	spawn_crystals()
	update_ui()

func spawn_crystals():
	var spawned_positions = []
	var attempts = 0
	var max_attempts = num_crystals * 10
	
	# Limpiar cristales existentes si reiniciamos
	for child in get_children():
		if child.has_method("collect"): 
			child.queue_free()
	
	total_crystals = 0
	collected_crystals = 0
	
	randomize() # Asegurar aleatoriedad en cada ejecución
	
	while total_crystals < num_crystals and attempts < max_attempts:
		attempts += 1
		
		# Generar posición aleatoria en el rango completo del mapa (Tiles 1, 2, 3, 4)
		var random_x = rand_range(map_min_x, map_max_x)
		var random_z = rand_range(map_min_z, map_max_z)
		var spawn_pos = Vector3(random_x, spawn_height, random_z)
		
		# Verificar distancia mínima con otros cristales
		var too_close = false
		for pos in spawned_positions:
			if spawn_pos.distance_to(pos) < min_distance_between_crystals:
				too_close = true
				break
		
		if too_close:
			continue
		
		# Crear cristal
		var crystal = crystal_scene.instance()
		crystal.translation = spawn_pos
		
		# Añadir variación aleatoria a la rotación inicial
		crystal.rotation.y = rand_range(0, TAU)
		
		# Añadir variación al tiempo de animación para que no estén sincronizados
		crystal.time_passed = rand_range(0, TAU)
		
		add_child(crystal)
		spawned_positions.append(spawn_pos)
		total_crystals += 1
	
	print("Cristales generados: ", total_crystals)

func on_crystal_collected():
	collected_crystals += 1
	update_ui()
	
	# Efecto de sonido (opcional, si tienes un AudioStreamPlayer)
	# $CollectSound.play()
	
	# Verificar si se recolectaron todos
	if collected_crystals >= total_crystals:
		print("¡Todos los cristales recolectados!")
		# Aquí puedes añadir lógica adicional (desbloquear algo, mostrar mensaje, etc.)

func update_ui():
	if crystal_label:
		# Ya no ponemos "Cristales:", solo el número
		crystal_label.text = str(collected_crystals) + " / " + str(total_crystals)

func _animate_icon(icon):
	if is_instance_valid(icon):
		icon.rotate_y(0.02)

func get_collected_count() -> int:
	return collected_crystals

func get_total_count() -> int:
	return total_crystals
