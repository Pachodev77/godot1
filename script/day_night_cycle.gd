extends Spatial

export var cycle_duration = 360.0  # 6 minutos para un ciclo completo
export var start_time = 0.5  # 0.0 es medianoche, 0.5 es mediodía

var time_of_day = 0.0

onready var sun = $DirectionalLight
onready var sun_visual = $DirectionalLight/SunVisual
onready var environment = $WorldEnvironment
onready var stars = $Stars
onready var player_camera = get_node_or_null("/root/Escena/jugador/Pivot/Camera")

var sky: ProceduralSky

# Cache para optimización
var cached_sun_height = 0.0
var last_update_time = 0.0
var update_interval = 0.016  # ~60 FPS
var last_sky_phase = -1  # -1=noche, 0=amanecer, 1=día, 2=atardecer
var last_sun_color = Color(1.0, 1.0, 1.0)

func _ready():
	time_of_day = start_time
	if environment and environment.environment and environment.environment.background_sky:
		sky = environment.environment.background_sky

func _process(delta):
	time_of_day += delta / cycle_duration
	if time_of_day >= 1.0:
		time_of_day -= 1.0
	
	last_update_time += delta
	
	# Actualizar solo cada update_interval para reducir carga
	if last_update_time >= update_interval:
		cached_sun_height = -cos(time_of_day * TAU)
		update_sun_position()
		update_lighting()
		update_sky_color()
		update_stars()
		last_update_time = 0.0

func update_sun_position():
	var t = time_of_day * TAU
	var altitude = asin(cached_sun_height)  # [-PI/2, PI/2]
	var azimuth = t                  # [0, 2PI)

	sun.rotation.x = altitude
	sun.rotation.y = azimuth

	if sky:
		sky.sun_latitude = rad2deg(altitude)
		sky.sun_longitude = rad2deg(azimuth)

func update_lighting():
	if cached_sun_height > 0.0:
		var intensity = clamp(cached_sun_height * 1.2, 0.0, 1.0)
		if intensity != sun.light_energy:
			sun.light_energy = intensity
			sun.visible = true
	else:
		if sun.light_energy != 0.0:
			sun.light_energy = 0.0
			sun.visible = false

	if time_of_day > 0.2 and time_of_day < 0.3:
		var t = (time_of_day - 0.2) / 0.1
		var new_color = Color(1.0, 0.7 + t * 0.3, 0.5 + t * 0.5)
		if new_color != last_sun_color:
			sun.light_color = new_color
			last_sun_color = new_color
	elif time_of_day > 0.7 and time_of_day < 0.8:
		var t = (time_of_day - 0.7) / 0.1
		var new_color = Color(1.0, 1.0 - t * 0.3, 1.0 - t * 0.5)
		if new_color != last_sun_color:
			sun.light_color = new_color
			last_sun_color = new_color
	else:
		sun.light_color = Color(1.0, 1.0, 1.0)

	if sky:
		sky.sun_energy = max(sun.light_energy, 0.0)

func update_sky_color():
	if not environment or not environment.environment or not sky:
		return
	
	var env = environment.environment
	var current_phase = -1
	
	# Determinar fase actual
	if cached_sun_height < -0.1:
		current_phase = -1  # Noche
	elif time_of_day >= 0.2 and time_of_day <= 0.3:
		current_phase = 0  # Amanecer
	elif cached_sun_height > 0.0:
		current_phase = 1  # Día
	elif time_of_day >= 0.7 and time_of_day <= 0.8:
		current_phase = 2  # Atardecer
	
	# Solo actualizar si cambió la fase
	if current_phase == last_sky_phase and current_phase != 0 and current_phase != 2:
		return
	
	last_sky_phase = current_phase
	
	# Noche
	if cached_sun_height < -0.1:
		sky.sky_top_color = Color(0.05, 0.05, 0.15)
		sky.sky_horizon_color = Color(0.1, 0.1, 0.2)
		sky.ground_bottom_color = Color(0.02, 0.02, 0.05)
		sky.ground_horizon_color = Color(0.05, 0.05, 0.1)
		env.ambient_light_color = Color(0.1, 0.1, 0.2)
		env.ambient_light_energy = 0.2
	
	# Amanecer
	elif time_of_day >= 0.2 and time_of_day <= 0.3:
		var t = (time_of_day - 0.2) / 0.1
		sky.sky_top_color = Color(0.05, 0.05, 0.15).linear_interpolate(Color(0.4, 0.6, 0.9), t)
		sky.sky_horizon_color = Color(1.0, 0.5, 0.3).linear_interpolate(Color(0.7, 0.8, 0.9), t)
		sky.ground_bottom_color = Color(0.1, 0.1, 0.1).linear_interpolate(Color(0.2, 0.3, 0.4), t)
		sky.ground_horizon_color = Color(0.3, 0.2, 0.1).linear_interpolate(Color(0.5, 0.6, 0.7), t)
		env.ambient_light_color = Color(1.0, 0.6, 0.4).linear_interpolate(Color(0.4, 0.6, 0.9), t)
		env.ambient_light_energy = 0.3 + t * 0.5
	
	# Día
	elif cached_sun_height > 0.0:
		sky.sky_top_color = Color(0.4, 0.6, 0.9)
		sky.sky_horizon_color = Color(0.7, 0.8, 0.9)
		sky.ground_bottom_color = Color(0.2, 0.3, 0.4)
		sky.ground_horizon_color = Color(0.5, 0.6, 0.7)
		env.ambient_light_color = Color(0.4, 0.6, 0.9)
		env.ambient_light_energy = 0.8
	
	# Atardecer
	elif time_of_day >= 0.7 and time_of_day <= 0.8:
		var t = (time_of_day - 0.7) / 0.1
		sky.sky_top_color = Color(0.4, 0.6, 0.9).linear_interpolate(Color(0.05, 0.05, 0.15), t)
		sky.sky_horizon_color = Color(0.7, 0.8, 0.9).linear_interpolate(Color(1.0, 0.4, 0.2), t)
		sky.ground_bottom_color = Color(0.2, 0.3, 0.4).linear_interpolate(Color(0.1, 0.1, 0.1), t)
		sky.ground_horizon_color = Color(0.5, 0.6, 0.7).linear_interpolate(Color(0.3, 0.2, 0.1), t)
		env.ambient_light_color = Color(0.4, 0.6, 0.9).linear_interpolate(Color(1.0, 0.5, 0.3), t)
		env.ambient_light_energy = 0.8 - t * 0.4

func update_stars():
    if not stars:
        return
    
    if cached_sun_height < -0.1:
        var visibility = clamp((-cached_sun_height - 0.1) / 0.3, 0.0, 1.0)
        stars.visible = true
        
        if stars.material_override:
            stars.material_override.set_shader_param("star_visibility", visibility)
        if player_camera:
            var t = stars.global_transform
            t.origin = player_camera.global_transform.origin
            stars.global_transform = t
    else:
        stars.visible = false
