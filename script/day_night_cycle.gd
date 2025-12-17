extends Spatial

export var cycle_duration = 360.0  # 6 minutos para un ciclo completo
export var start_time = 0.5  # 0.0 es medianoche, 0.5 es mediodía

var time_of_day = 0.0

onready var sun = $DirectionalLight
onready var sun_visual = $DirectionalLight/SunVisual
onready var environment = $WorldEnvironment
onready var stars = $Stars

var sky: ProceduralSky

func _ready():
	time_of_day = start_time
	if environment and environment.environment and environment.environment.background_sky:
		sky = environment.environment.background_sky

func _process(delta):
	time_of_day += delta / cycle_duration
	if time_of_day >= 1.0:
		time_of_day -= 1.0
	
	update_sun_position()
	update_lighting()
	update_sky_color()
	update_stars()

func update_sun_position():
	var sun_angle = time_of_day * TAU
	sun.rotation.x = sun_angle

func update_lighting():
	var sun_height = -cos(time_of_day * PI * 2.0)
	
	if sun_height > 0.0:
		var intensity = clamp(sun_height * 1.2, 0.0, 1.0)
		sun.light_energy = intensity
		sun.visible = true
	else:
		sun.light_energy = 0.0
		sun.visible = false
	
	var dawn_dusk_factor = 1.0 - abs(sun_height)
	dawn_dusk_factor = pow(dawn_dusk_factor, 2.0)
	
	if time_of_day > 0.2 and time_of_day < 0.3:
		var t = (time_of_day - 0.2) / 0.1
		sun.light_color = Color(1.0, 0.7 + t * 0.3, 0.5 + t * 0.5)
	elif time_of_day > 0.7 and time_of_day < 0.8:
		var t = (time_of_day - 0.7) / 0.1
		sun.light_color = Color(1.0, 1.0 - t * 0.3, 1.0 - t * 0.5)
	else:
		sun.light_color = Color(1.0, 1.0, 1.0)

func update_sky_color():
	if not environment or not environment.environment or not sky:
		return
	
	var env = environment.environment
	var sun_height = -cos(time_of_day * PI * 2.0)
	
	# Noche
	if sun_height < -0.1:
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
	elif sun_height > 0.0:
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
	
	var sun_height = -cos(time_of_day * PI * 2.0)
	
	if sun_height < -0.1:
		var visibility = clamp((-sun_height - 0.1) / 0.3, 0.0, 1.0)
		stars.visible = true
		
		if stars.material_override:
			stars.material_override.set_shader_param("star_visibility", visibility)
	else:
		stars.visible = false
