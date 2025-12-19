extends Spatial

var nodes_to_process = []
var current_index = 0
var nodes_per_frame = 2  # Procesar solo 2 nodos por frame para evitar lag

func _ready():
	call_deferred("fix_materials_deferred")

func fix_materials_deferred():
	collect_nodes(self)
	if nodes_to_process.size() > 0:
		set_process(true)

func collect_nodes(node):
	if node is MeshInstance:
		nodes_to_process.append(node)
	
	for child in node.get_children():
		collect_nodes(child)

func _process(delta):
	var processed = 0
	while current_index < nodes_to_process.size() and processed < nodes_per_frame:
		var node = nodes_to_process[current_index]
		if node and is_instance_valid(node):
			process_mesh_node(node)
		current_index += 1
		processed += 1
	
	if current_index >= nodes_to_process.size():
		set_process(false)

func process_mesh_node(node):
	var should_collide = false
	var mesh = node.mesh
	if mesh != null:
		for i in range(mesh.get_surface_count()):
			var mat = mesh.surface_get_material(i)
			if mat == null:
				mat = node.get_surface_material(i)
			
			if mat != null:
				var mat_name = mat.resource_name
				if "Floor" in mat_name or "Wood" in mat_name:
					should_collide = true
				
				if mat is SpatialMaterial:
						var new_mat = mat.duplicate()
						new_mat.flags_transparent = false
						new_mat.params_use_alpha_scissor = true
						new_mat.params_alpha_scissor_threshold = 0.5
						new_mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
						
						mesh.surface_set_material(i, new_mat)
						node.set_surface_material(i, new_mat)
	
	if should_collide:
		node.create_trimesh_collision()
