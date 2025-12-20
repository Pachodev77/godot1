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
	
	# Si no existe, crear uno
	if crystal_label == null:
		var canvas_layer = get_node_or_null("/root/Escena/CanvasLayer")
		if canvas_layer:
			crystal_label = Label.new()
			crystal_label.name = "CrystalLabel"
			crystal_label.rect_position = Vector2(20, 20)
			crystal_label.rect_scale = Vector2(2, 2)
			crystal_label.add_color_override("font_color", Color(0.4, 0.8, 1, 1))
			canvas_layer.add_child(crystal_label)
	
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
		crystal_label.text = "Cristales: " + str(collected_crystals) + "/" + str(total_crystals)

func get_collected_count() -> int:
	return collected_crystals

func get_total_count() -> int:
	return total_crystals
