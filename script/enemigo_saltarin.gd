extends KinematicBody

# Configuración del enemigo
export var speed : float = 5.0
export var jump_force : float = 12.0
export var gravity : float = 30.0
export var attack_range : float = 12.0

# Variables de estado
var velocity := Vector3.ZERO
var target : Spatial = null
var jump_timer : float = 0.0
export var jump_interval : float = 1.2
var is_jumping := false

onready var mesh = $MeshInstance
onready var anim_timer = $JumpInterval

func _ready():
	_find_target()
	randomize()
	jump_timer = rand_range(0, jump_interval)
	
	# Mejorar visibilidad (evitar que desaparezcan por culling)
	if mesh:
		for child in mesh.get_children():
			if child is VisualInstance:
				child.extra_cull_margin = 100.0

func _find_target():
	var players = get_tree().get_nodes_in_group("jugador")
	if players.size() > 0:
		target = players[0]

func _physics_process(delta):
	# Aplicar gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		velocity.x = lerp(velocity.x, 0, 0.1)
		velocity.z = lerp(velocity.z, 0, 0.1)
		is_jumping = false

	if !target:
		_find_target()

	if target and !is_jumping:
		var dist = global_transform.origin.distance_to(target.global_transform.origin)
		
		# Siempre buscar al jugador (eliminado el check de detection_range)
		# Mirar hacia el jugador (solo en el eje Y)
		var look_pos = target.global_transform.origin
		look_pos.y = global_transform.origin.y
		if global_transform.origin.distance_to(look_pos) > 0.1:
			look_at(look_pos, Vector3.UP)
		
		jump_timer -= delta
		if jump_timer <= 0:
			perform_jump(dist)
			jump_timer = jump_interval

	velocity = move_and_slide(velocity, Vector3.UP)

func perform_jump(dist_to_player):
	is_jumping = true
	
	# Calcular dirección horizontal hacia el objetivo
	var dir = (target.global_transform.origin - global_transform.origin).normalized()
	dir.y = 0
	dir = dir.normalized()
	
	# Ajustar fuerza de salto según la distancia (ataque)
	var current_jump = jump_force
	var current_speed = speed
	
	if dist_to_player < attack_range:
		# Salto de ataque: más alto y más rápido
		current_jump *= 1.3
		current_speed *= 1.5
	
	velocity.y = current_jump
	velocity.x = dir.x * current_speed
	velocity.z = dir.z * current_speed
	
	# Pequeño efecto visual de escala al saltar
	tween_jump_effect()

func tween_jump_effect():
	# Efecto visual simple sin necesidad de AnimationPlayer
	var t = create_tween() if has_method("create_tween") else null
	if t:
		t.tween_property(mesh, "scale", Vector3(0.8, 1.3, 0.8), 0.1)
		t.parallel().tween_property(mesh, "translation:y", 0.2, 0.1)
		t.tween_property(mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.2)
		t.parallel().tween_property(mesh, "translation:y", 0.0, 0.2)
