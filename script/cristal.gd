extends Area

# Configuración del cristal
export var rotation_speed : float = 2.0
export var float_amplitude : float = 0.3
export var float_speed : float = 2.0
export var fade_duration : float = 0.5

# Variables internas
var initial_y : float = 0.0
var time_passed : float = 0.0
var is_collected : bool = false
var fade_timer : float = 0.0
export var is_ui_icon : bool = false

# Referencias
onready var mesh_instance = $MeshInstance
onready var collision_shape = $CollisionShape

func _ready():
	initial_y = translation.y
	generate_diamond_mesh()
	if !is_ui_icon:
		connect("body_entered", self, "_on_body_entered")

func generate_diamond_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Usar el material existente si hay uno
	var mat = null
	if mesh_instance.mesh and mesh_instance.get_surface_material(0):
		mat = mesh_instance.get_surface_material(0).duplicate()
	elif mesh_instance.material_override:
		mat = mesh_instance.material_override.duplicate()
	else:
		# Material por defecto si no encuentra uno
		mat = SpatialMaterial.new()
		mat.albedo_color = Color(0.6, 0.2, 0.9)
		mat.emission_enabled = true
		mat.emission = Color(0.5, 0.1, 0.8)
		mat.emission_energy = 2.0
		
	st.set_material(mat)
	
	# Dimensiones
	var w = 0.25 # Ancho/2 (Radio horizontal)
	var h = 0.5  # Altura/2 (Radio vertical)
	
	# Vértices Principales
	var top = Vector3(0, h, 0)
	var bottom = Vector3(0, -h, 0)
	var v_front = Vector3(0, 0, w)
	var v_right = Vector3(w, 0, 0)
	var v_back = Vector3(0, 0, -w)
	var v_left = Vector3(-w, 0, 0)
	
	# Pirámide Superior (Normales hacia arriba/fuera)
	# Cara Frontal-Derecha
	add_triangle(st, top, v_right, v_front)
	# Cara Frontal-Izquierda
	add_triangle(st, top, v_front, v_left)
	# Cara Trasera-Izquierda
	add_triangle(st, top, v_left, v_back)
	# Cara Trasera-Derecha
	add_triangle(st, top, v_back, v_right)
	
	# Pirámide Inferior (Normales hacia abajo/fuera)
	# Cara Frontal-Derecha
	add_triangle(st, bottom, v_front, v_right)
	# Cara Frontal-Izquierda
	add_triangle(st, bottom, v_left, v_front)
	# Cara Trasera-Izquierda
	add_triangle(st, bottom, v_back, v_left)
	# Cara Trasera-Derecha
	add_triangle(st, bottom, v_right, v_back)
	
	st.generate_normals()
	
	var mesh = st.commit()
	
	# CORRECCIÓN IMPORTANTE: Aumentar el AABB (Caja de límites)
	# Esto evita que el motor oculte (culling) el objeto prematuramente
	# Al generarse por código, a veces el AABB es muy pequeño
	var aabb = mesh.get_aabb()
	aabb = aabb.grow(2.0) # Aumentar 2 metros extra por si acaso
	mesh.custom_aabb = aabb
	
	mesh_instance.mesh = mesh
	# IMPORTANTE: Asignar el material único directamente al nodo MeshInstance
	# para sobrescribir el material compartido que viene de la escena (.tscn)
	mesh_instance.set_surface_material(0, mat)
	
	# Asegurar que no se oculte por distancia demasiado pronto
	mesh_instance.extra_cull_margin = 100.0

func add_triangle(st, v1, v2, v3):
	st.add_uv(Vector2(0.5, 1))
	st.add_vertex(v1)
	st.add_uv(Vector2(1, 0))
	st.add_vertex(v2)
	st.add_uv(Vector2(0, 0))
	st.add_vertex(v3)

func _process(delta):
	if is_collected:
		fade_timer += delta
		var fade_progress = fade_timer / fade_duration
		
		if fade_progress >= 1.0:
			queue_free()
			return
		
		# Efecto de desaparecer
		var scale_val = 1.0 + fade_progress * 0.5
		mesh_instance.scale = Vector3(scale_val, scale_val, scale_val)
		
		# Modificar el material único que ya asignamos
		var mat = mesh_instance.get_surface_material(0)
		if mat:
			# Activar transparencia si no está activa
			if not mat.flags_transparent:
				mat.flags_transparent = true
				
			var color = mat.albedo_color
			color.a = 1.0 - fade_progress
			mat.albedo_color = color
		
		translation.y = initial_y + time_passed * float_amplitude + fade_progress * 2.0
		rotate_y(rotation_speed * delta * 4.0)
	else:
		time_passed += delta * float_speed
		translation.y = initial_y + sin(time_passed) * float_amplitude
		rotate_y(rotation_speed * delta)

func _on_body_entered(body):
	if is_collected: return
	if body.name == "jugador":
		collect()

func collect():
	is_collected = true
	fade_timer = 0.0
	collision_shape.disabled = true
	
	var manager = get_node_or_null("/root/Escena/CrystalManager")
	if manager:
		manager.on_crystal_collected()
