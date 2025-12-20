extends Spatial

# Configuración de Spawning
export var num_enemies : int = 20
export var spawn_min_x : float = 20.0
export var spawn_max_x : float = 280.0
export var spawn_min_z : float = 20.0
export var spawn_max_z : float = 280.0
export var spawn_height : float = 5.0

# Escena del enemigo
var enemy_scene = preload("res://escena/enemigo_saltarin.tscn")

func _ready():
	# Retrasar un poco el spawn inicial para asegurar que el mapa esté listo
	yield(get_tree().create_timer(1.0), "timeout")
	spawn_enemies()

func spawn_enemies():
	randomize()
	for i in range(num_enemies):
		var random_x = rand_range(spawn_min_x, spawn_max_x)
		var random_z = rand_range(spawn_min_z, spawn_max_z)
		
		var enemy = enemy_scene.instance()
		enemy.translation = Vector3(random_x, spawn_height, random_z)
		
		# Variación aleatoria en la escala para que no sean todos iguales
		var s = rand_range(0.8, 1.2)
		enemy.scale = Vector3(s, s, s)
		
		add_child(enemy)
	
	print("Enemigos saltarines generados: ", num_enemies)
