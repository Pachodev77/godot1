extends Spatial

# Cache processed materials to avoid duplication explosion
var material_cache = {}
var shape_cache = {}
var nodes_to_process = []
var current_index = 0
var nodes_per_frame = 5 # Increased slightly as logic is now lighter

func _ready():
	# Wait for scene to be fully initialized
	call_deferred("fix_materials_deferred")

func fix_materials_deferred():
	collect_nodes(self)
	if nodes_to_process.size() > 0:
		set_process(true)
	else:
		set_process(false)

func collect_nodes(node):
	if node is MeshInstance:
		nodes_to_process.append(node)
	
	for child in node.get_children():
		collect_nodes(child)

func _process(_delta):
	var processed = 0
	while current_index < nodes_to_process.size() and processed < nodes_per_frame:
		var node = nodes_to_process[current_index]
		if is_instance_valid(node):
			process_mesh_node(node)
		current_index += 1
		processed += 1
	
	if current_index >= nodes_to_process.size():
		set_process(false)
		print("Forest optimization complete: ", nodes_to_process.size(), " nodes processed.")
		# Clear references
		nodes_to_process.clear()
		material_cache.clear()

func process_mesh_node(node):
	var mesh = node.mesh
	if not mesh:
		return
		
	var needs_collision = false
	
	for i in range(mesh.get_surface_count()):
		var mat = mesh.surface_get_material(i)
		# If no override on mesh, check node override (unlikely for imported scenes but possible)
		if mat == null:
			mat = node.get_surface_material(i)
		
		# If still null, we can't do anything (it uses default default material)
		if mat == null:
			continue
			
		var mat_name = mat.resource_name
		var low_name = mat_name.to_lower() if mat_name else ""
		
		# --- COLLISION LOGIC ---
		# Only collide with trunks (wood) and ground (floor)
		# Explicitly EXCLUDE leaves/foliage/grass from collision to save physics cost
		if "wood" in low_name or "floor" in low_name:
			needs_collision = true
		
		# --- MATERIAL LOGIC ---
		if mat is SpatialMaterial:
			# Check cache first
			if material_cache.has(mat):
				var cached_mat = material_cache[mat]
				node.set_surface_material(i, cached_mat)
			else:
				# Create new fixed material
				var new_mat = mat.duplicate()
				
				# Fix settings for Mobile/Vegetation
				new_mat.flags_transparent = false # Disable alpha blending
				new_mat.params_use_alpha_scissor = true # Enable cutout
				new_mat.params_alpha_scissor_threshold = 0.15 # Low threshold to keep fine details
				new_mat.params_cull_mode = SpatialMaterial.CULL_DISABLED # Double Sided
				
				# Ensure depth draw is correct
				new_mat.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_OPAQUE_ONLY
				
				# Cache it
				material_cache[mat] = new_mat
				print("Optimized Material Cached: ", mat_name)
				
				# Apply
				node.set_surface_material(i, new_mat)

	# Apply collision if needed and not already present
	if needs_collision:
		# check if it already has a static body child (simple check)
		var has_collision = false
		for child in node.get_children():
			if child is StaticBody:
				has_collision = true
				break
		
		if not has_collision:
			# PHYSICS OPTIMIZATION: Cache collision shapes based on Mesh resource
			# This prevents creating unique ConcavePolygonShape for every instance (huge memory saving)
			if shape_cache.has(mesh):
				_create_collision_from_cache(node, shape_cache[mesh])
			else:
				# Create valid Trimesh shape (most accurate for trees) or Convex (lighter but approximate)
				# Using Trimesh as it is standard, but now cached it is safe.
				var shape = mesh.create_trimesh_shape()
				if shape:
					shape_cache[mesh] = shape
					_create_collision_from_cache(node, shape)
					print("Physics Shape Cached for Mesh: ", mesh.resource_name)

func _create_collision_from_cache(node, shape):
	var sb = StaticBody.new()
	var cs = CollisionShape.new()
	cs.shape = shape
	sb.add_child(cs)
	node.add_child(sb)
	# Set owner to allow manual scene saving if needed, but mostly internal

