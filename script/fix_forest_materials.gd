extends Spatial

func _ready():
	call_deferred("fix_materials_deferred")

func fix_materials_deferred():
	fix_materials(self)

func fix_materials(node):
	if node is MeshInstance:
		var should_collide = false
		var mesh = node.mesh
		if mesh != null:
			for i in range(mesh.get_surface_count()):
				var mat = mesh.surface_get_material(i)
				if mat == null:
					mat = node.get_surface_material(i)
				
				if mat != null:
					# Filtro de colisiones por nombre de material (Suelo y Troncos)
					var mat_name = mat.resource_name
					if "Floor" in mat_name or "Wood" in mat_name:
						should_collide = true
					
					if mat is SpatialMaterial:
						if mat.flags_transparent:
							mat.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_ALPHA_OPAQUE_PREPASS
							mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
							
							mesh.surface_set_material(i, mat)
							node.set_surface_material(i, mat)
		
		if should_collide:
			node.create_trimesh_collision()
	
	for child in node.get_children():
		fix_materials(child)
