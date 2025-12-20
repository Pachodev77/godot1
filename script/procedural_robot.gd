extends Spatial

# Este script genera un robot humanoide procedural con todas sus partes

# Materiales
var metal_material = SpatialMaterial.new()
var visor_material = SpatialMaterial.new()
var accent_material = SpatialMaterial.new()
var jetpack_material = SpatialMaterial.new()

func _ready():
	setup_materials()
	generate_robot()

func setup_materials():
	# Material metálico principal
	metal_material.albedo_color = Color(0.3, 0.3, 0.35)
	metal_material.metallic = 0.9
	metal_material.roughness = 0.3
	
	# Material del visor (azul brillante)
	visor_material.albedo_color = Color(0.1, 0.4, 1.0)
	visor_material.metallic = 0.5
	visor_material.roughness = 0.1
	visor_material.emission_enabled = true
	visor_material.emission = Color(0.2, 0.6, 1.0)
	visor_material.emission_energy = 1.5
	
	# Material de acentos (azul oscuro)
	accent_material.albedo_color = Color(0.1, 0.2, 0.4)
	accent_material.metallic = 0.7
	accent_material.roughness = 0.4
	
	# Material del jetpack (con emisión naranja)
	jetpack_material.albedo_color = Color(0.2, 0.2, 0.25)
	jetpack_material.metallic = 0.85
	jetpack_material.roughness = 0.35
	jetpack_material.emission_enabled = true
	jetpack_material.emission = Color(1.0, 0.5, 0.1)
	jetpack_material.emission_energy = 0.5

func generate_robot():
	# Crear esqueleto
	var skeleton = Skeleton.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	
	# Crear huesos
	create_bones(skeleton)
	
	# Generar partes del cuerpo
	create_head(skeleton)
	create_torso(skeleton)
	create_arms(skeleton)
	create_legs(skeleton)
	create_jetpack(skeleton)

func create_bones(skeleton):
	# Primero añadir todos los huesos
	skeleton.add_bone("Hips")
	skeleton.add_bone("Spine")
	skeleton.add_bone("Chest")
	skeleton.add_bone("Neck")
	skeleton.add_bone("Head")
	skeleton.add_bone("LeftShoulder")
	skeleton.add_bone("LeftUpperArm")
	skeleton.add_bone("LeftForearm")
	skeleton.add_bone("LeftHand")
	skeleton.add_bone("RightShoulder")
	skeleton.add_bone("RightUpperArm")
	skeleton.add_bone("RightForearm")
	skeleton.add_bone("RightHand")
	skeleton.add_bone("LeftUpperLeg")
	skeleton.add_bone("LeftLowerLeg")
	skeleton.add_bone("LeftFoot")
	skeleton.add_bone("RightUpperLeg")
	skeleton.add_bone("RightLowerLeg")
	skeleton.add_bone("RightFoot")
	skeleton.add_bone("Jetpack")
	
	# Obtener índices
	var hips_idx = skeleton.find_bone("Hips")
	var spine_idx = skeleton.find_bone("Spine")
	var chest_idx = skeleton.find_bone("Chest")
	var neck_idx = skeleton.find_bone("Neck")
	var head_idx = skeleton.find_bone("Head")
	var l_shoulder_idx = skeleton.find_bone("LeftShoulder")
	var l_upper_arm_idx = skeleton.find_bone("LeftUpperArm")
	var l_forearm_idx = skeleton.find_bone("LeftForearm")
	var l_hand_idx = skeleton.find_bone("LeftHand")
	var r_shoulder_idx = skeleton.find_bone("RightShoulder")
	var r_upper_arm_idx = skeleton.find_bone("RightUpperArm")
	var r_forearm_idx = skeleton.find_bone("RightForearm")
	var r_hand_idx = skeleton.find_bone("RightHand")
	var l_upper_leg_idx = skeleton.find_bone("LeftUpperLeg")
	var l_lower_leg_idx = skeleton.find_bone("LeftLowerLeg")
	var l_foot_idx = skeleton.find_bone("LeftFoot")
	var r_upper_leg_idx = skeleton.find_bone("RightUpperLeg")
	var r_lower_leg_idx = skeleton.find_bone("RightLowerLeg")
	var r_foot_idx = skeleton.find_bone("RightFoot")
	var jetpack_idx = skeleton.find_bone("Jetpack")
	
	# Configurar jerarquía (padres)
	skeleton.set_bone_parent(spine_idx, hips_idx)
	skeleton.set_bone_parent(chest_idx, spine_idx)
	skeleton.set_bone_parent(neck_idx, chest_idx)
	skeleton.set_bone_parent(head_idx, neck_idx)
	
	skeleton.set_bone_parent(l_shoulder_idx, chest_idx)
	skeleton.set_bone_parent(l_upper_arm_idx, l_shoulder_idx)
	skeleton.set_bone_parent(l_forearm_idx, l_upper_arm_idx)
	skeleton.set_bone_parent(l_hand_idx, l_forearm_idx)
	
	skeleton.set_bone_parent(r_shoulder_idx, chest_idx)
	skeleton.set_bone_parent(r_upper_arm_idx, r_shoulder_idx)
	skeleton.set_bone_parent(r_forearm_idx, r_upper_arm_idx)
	skeleton.set_bone_parent(r_hand_idx, r_forearm_idx)
	
	skeleton.set_bone_parent(l_upper_leg_idx, hips_idx)
	skeleton.set_bone_parent(l_lower_leg_idx, l_upper_leg_idx)
	skeleton.set_bone_parent(l_foot_idx, l_lower_leg_idx)
	
	skeleton.set_bone_parent(r_upper_leg_idx, hips_idx)
	skeleton.set_bone_parent(r_lower_leg_idx, r_upper_leg_idx)
	skeleton.set_bone_parent(r_foot_idx, r_lower_leg_idx)
	
	skeleton.set_bone_parent(jetpack_idx, chest_idx)
	
	# Configurar poses (posiciones relativas)
	skeleton.set_bone_pose(hips_idx, Transform(Basis(), Vector3(0, 0.87, 0)))
	skeleton.set_bone_pose(spine_idx, Transform(Basis(), Vector3(0, 0.2, 0)))
	skeleton.set_bone_pose(chest_idx, Transform(Basis(), Vector3(0, 0.3, 0)))
	skeleton.set_bone_pose(neck_idx, Transform(Basis(), Vector3(0, 0.25, 0)))
	skeleton.set_bone_pose(head_idx, Transform(Basis(), Vector3(0, 0.15, 0)))
	
	# Brazos izquierdos - apuntando hacia abajo naturalmente
	skeleton.set_bone_pose(l_shoulder_idx, Transform(Basis(), Vector3(-0.25, 0.4, 0)))
	skeleton.set_bone_pose(l_upper_arm_idx, Transform(Basis(), Vector3(0, -0.05, 0)))
	skeleton.set_bone_pose(l_forearm_idx, Transform(Basis(), Vector3(0, -0.32, 0)))
	skeleton.set_bone_pose(l_hand_idx, Transform(Basis(), Vector3(0, -0.28, 0)))
	
	# Brazos derechos - apuntando hacia abajo naturalmente
	skeleton.set_bone_pose(r_shoulder_idx, Transform(Basis(), Vector3(0.25, 0.4, 0)))
	skeleton.set_bone_pose(r_upper_arm_idx, Transform(Basis(), Vector3(0, -0.05, 0)))
	skeleton.set_bone_pose(r_forearm_idx, Transform(Basis(), Vector3(0, -0.32, 0)))
	skeleton.set_bone_pose(r_hand_idx, Transform(Basis(), Vector3(0, -0.28, 0)))
	
	skeleton.set_bone_pose(l_upper_leg_idx, Transform(Basis(), Vector3(-0.15, 0, 0)))
	skeleton.set_bone_pose(l_lower_leg_idx, Transform(Basis(), Vector3(0, -0.4, 0)))
	skeleton.set_bone_pose(l_foot_idx, Transform(Basis(), Vector3(0, -0.35, 0)))
	
	skeleton.set_bone_pose(r_upper_leg_idx, Transform(Basis(), Vector3(0.15, 0, 0)))
	skeleton.set_bone_pose(r_lower_leg_idx, Transform(Basis(), Vector3(0, -0.4, 0)))
	skeleton.set_bone_pose(r_foot_idx, Transform(Basis(), Vector3(0, -0.35, 0)))
	
	skeleton.set_bone_pose(jetpack_idx, Transform(Basis(), Vector3(0, 0.1, -0.15)))

func create_head(skeleton):
	var bone_attach = BoneAttachment.new()
	bone_attach.bone_name = "Head"
	skeleton.add_child(bone_attach)
	
	# Cabeza principal
	var head_mesh = CSGBox.new()
	head_mesh.width = 0.25
	head_mesh.height = 0.28
	head_mesh.depth = 0.25
	head_mesh.material = metal_material
	bone_attach.add_child(head_mesh)
	
	# Visor
	var visor = CSGBox.new()
	visor.width = 0.26
	visor.height = 0.08
	visor.depth = 0.02
	visor.translation = Vector3(0, 0.05, 0.125)
	visor.material = visor_material
	head_mesh.add_child(visor)
	
	# Antena pequeña
	var antenna = CSGCylinder.new()
	antenna.radius = 0.015
	antenna.height = 0.1
	antenna.translation = Vector3(0, 0.19, 0)
	antenna.material = accent_material
	head_mesh.add_child(antenna)

	# Detalles de cabeza
	var ear_l = CSGBox.new()
	ear_l.width = 0.05
	ear_l.height = 0.16
	ear_l.depth = 0.16
	ear_l.translation = Vector3(-0.13, 0, 0)
	ear_l.material = accent_material
	head_mesh.add_child(ear_l)
	
	var ear_r = CSGBox.new()
	ear_r.width = 0.05
	ear_r.height = 0.16
	ear_r.depth = 0.16
	ear_r.translation = Vector3(0.13, 0, 0)
	ear_r.material = accent_material
	head_mesh.add_child(ear_r)
	
	var chin = CSGBox.new()
	chin.width = 0.18
	chin.height = 0.06
	chin.depth = 0.05
	chin.translation = Vector3(0, -0.11, 0.11)
	chin.material = accent_material
	head_mesh.add_child(chin)

func create_torso(skeleton):
	# Pecho
	var chest_attach = BoneAttachment.new()
	chest_attach.bone_name = "Chest"
	skeleton.add_child(chest_attach)
	
	var chest = CSGBox.new()
	chest.width = 0.45
	chest.height = 0.35
	chest.depth = 0.25
	chest.material = metal_material
	chest_attach.add_child(chest)
	
	# Detalles de Torso
	var vent = CSGBox.new()
	vent.width = 0.28
	vent.height = 0.12
	vent.depth = 0.05
	vent.translation = Vector3(0, 0.08, 0.11)
	vent.material = jetpack_material
	chest.add_child(vent)
	
	# Placa pectoral
	var chest_plate = CSGBox.new()
	chest_plate.width = 0.35
	chest_plate.height = 0.25
	chest_plate.depth = 0.02
	chest_plate.translation = Vector3(0, 0.05, 0.135)
	chest_plate.material = accent_material
	chest.add_child(chest_plate)
	
	# Spine/Abdomen
	var spine_attach = BoneAttachment.new()
	spine_attach.bone_name = "Spine"
	skeleton.add_child(spine_attach)
	
	var abdomen = CSGBox.new()
	abdomen.width = 0.35
	abdomen.height = 0.25
	abdomen.depth = 0.22
	abdomen.material = metal_material
	spine_attach.add_child(abdomen)
	
	# Cadera
	var hips_attach = BoneAttachment.new()
	hips_attach.bone_name = "Hips"
	skeleton.add_child(hips_attach)
	
	var hips = CSGBox.new()
	hips.width = 0.4
	hips.height = 0.18
	hips.depth = 0.24
	hips.material = metal_material
	hips_attach.add_child(hips)

func create_arms(skeleton):
	# Brazo izquierdo
	create_arm(skeleton, "Left", -1)
	# Brazo derecho
	create_arm(skeleton, "Right", 1)

func create_arm(skeleton, side, dir):
	# Hombro
	var shoulder_attach = BoneAttachment.new()
	shoulder_attach.bone_name = side + "Shoulder"
	skeleton.add_child(shoulder_attach)
	

	
	# Hombrera (Shoulder Pad)
	var pad = CSGBox.new()
	pad.width = 0.22
	pad.height = 0.08
	pad.depth = 0.22
	pad.translation = Vector3(0, 0.1, 0)
	pad.material = accent_material
	shoulder_attach.add_child(pad)
	
	# Brazo superior (vertical hacia abajo)
	var upper_arm_attach = BoneAttachment.new()
	upper_arm_attach.bone_name = side + "UpperArm"
	skeleton.add_child(upper_arm_attach)
	
	var upper_arm = CSGCylinder.new()
	upper_arm.radius = 0.08
	upper_arm.height = 0.35
	upper_arm.translation = Vector3(0, -0.175, 0)  # Centrado verticalmente
	upper_arm.material = metal_material
	upper_arm_attach.add_child(upper_arm)
	
	# Codo
	var forearm_attach = BoneAttachment.new()
	forearm_attach.bone_name = side + "Forearm"
	skeleton.add_child(forearm_attach)
	
	var elbow = CSGSphere.new()
	elbow.radius = 0.07
	elbow.material = accent_material
	forearm_attach.add_child(elbow)
	
	# Antebrazo (vertical hacia abajo)
	var forearm = CSGCylinder.new()
	forearm.radius = 0.07
	forearm.height = 0.30
	forearm.translation = Vector3(0, -0.15, 0)  # Centrado verticalmente
	forearm.material = metal_material
	forearm_attach.add_child(forearm)
	
	# Guantelete
	var gauntlet = CSGBox.new()
	gauntlet.width = 0.15
	gauntlet.height = 0.18
	gauntlet.depth = 0.15
	gauntlet.translation = Vector3(0, 0, 0)
	gauntlet.material = accent_material
	forearm.add_child(gauntlet)
	
	# Mano
	var hand_attach = BoneAttachment.new()
	hand_attach.bone_name = side + "Hand"
	skeleton.add_child(hand_attach)
	
	var hand = CSGBox.new()
	hand.width = 0.12
	hand.height = 0.15
	hand.depth = 0.08
	hand.translation = Vector3(0, -0.075, 0)  # Centrada verticalmente
	hand.material = metal_material
	hand_attach.add_child(hand)

func create_legs(skeleton):
	create_leg(skeleton, "Left", -1)
	create_leg(skeleton, "Right", 1)

func create_leg(skeleton, side, dir):
	# Muslo
	var upper_leg_attach = BoneAttachment.new()
	upper_leg_attach.bone_name = side + "UpperLeg"
	skeleton.add_child(upper_leg_attach)
	
	var thigh = CSGCylinder.new()
	thigh.radius = 0.11
	thigh.height = 0.4
	thigh.translation = Vector3(0, -0.2, 0)
	thigh.material = metal_material
	upper_leg_attach.add_child(thigh)
	
	# Placa Muslo
	var thigh_plate = CSGBox.new()
	thigh_plate.width = 0.23
	thigh_plate.height = 0.25
	thigh_plate.depth = 0.05
	thigh_plate.translation = Vector3(0, 0, 0.09)
	thigh_plate.material = accent_material
	thigh.add_child(thigh_plate)
	
	# Rodilla
	var lower_leg_attach = BoneAttachment.new()
	lower_leg_attach.bone_name = side + "LowerLeg"
	skeleton.add_child(lower_leg_attach)
	
	var knee = CSGSphere.new()
	knee.radius = 0.09
	knee.material = accent_material
	lower_leg_attach.add_child(knee)
	
	# Rodillera
	var kneepad = CSGBox.new()
	kneepad.width = 0.14
	kneepad.height = 0.14
	kneepad.depth = 0.05
	kneepad.translation = Vector3(0, 0, 0.08)
	kneepad.material = accent_material
	knee.add_child(kneepad)
	
	# Espinilla
	var shin = CSGCylinder.new()
	shin.radius = 0.09
	shin.height = 0.35
	shin.translation = Vector3(0, -0.175, 0)
	shin.material = metal_material
	lower_leg_attach.add_child(shin)
	
	# Pie
	var foot_attach = BoneAttachment.new()
	foot_attach.bone_name = side + "Foot"
	skeleton.add_child(foot_attach)
	
	var foot = CSGBox.new()
	foot.width = 0.15
	foot.height = 0.12
	foot.depth = 0.25
	foot.translation = Vector3(0, -0.06, 0.05)
	foot.material = metal_material
	foot_attach.add_child(foot)

func create_jetpack(skeleton):
	var jetpack_attach = BoneAttachment.new()
	jetpack_attach.bone_name = "Jetpack"
	skeleton.add_child(jetpack_attach)
	
	# Cuerpo principal del jetpack
	var body = CSGBox.new()
	body.width = 0.3
	body.height = 0.4
	body.depth = 0.15
	body.material = jetpack_material
	jetpack_attach.add_child(body)
	
	# Propulsor izquierdo
	var thruster_l = CSGCylinder.new()
	thruster_l.radius = 0.08
	thruster_l.height = 0.35
	thruster_l.translation = Vector3(-0.1, -0.1, 0)
	thruster_l.material = jetpack_material
	body.add_child(thruster_l)
	
	# Propulsor derecho
	var thruster_r = CSGCylinder.new()
	thruster_r.radius = 0.08
	thruster_r.height = 0.35
	thruster_r.translation = Vector3(0.1, -0.1, 0)
	thruster_r.material = jetpack_material
	body.add_child(thruster_r)
	
	# Luces de propulsión
	var light_l = CSGSphere.new()
	light_l.radius = 0.06
	light_l.translation = Vector3(-0.1, -0.275, 0)
	light_l.material = visor_material
	body.add_child(light_l)
	
	var light_r = CSGSphere.new()
	light_r.radius = 0.06
	light_r.translation = Vector3(0.1, -0.275, 0)
	light_r.material = visor_material
	body.add_child(light_r)
