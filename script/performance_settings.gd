extends CanvasLayer

onready var panel = $SettingsPanel
onready var setup_button = $SetupButton

# Nodes to control
var sun: DirectionalLight
var day_night_system: Spatial

func _ready():
	panel.hide()
	setup_button.connect("pressed", self, "_on_setup_pressed")
	
	# Aplicar efecto de gota de agua a todos los botones
	_apply_water_drops(self)
	
	# Connect toggles
	$SettingsPanel/VBoxContainer/GridContainer/ShadowToggle.connect("toggled", self, "_on_shadow_toggled")
	$SettingsPanel/VBoxContainer/GridContainer/DayNightToggle.connect("toggled", self, "_on_day_night_toggled")
	$SettingsPanel/VBoxContainer/CloseButton.connect("pressed", self, "_on_close_pressed")
	
	# Find nodes
	sun = get_node_or_null("/root/Escena/DayNightSystem/DirectionalLight")
	day_night_system = get_node_or_null("/root/Escena/DayNightSystem")
	
	# Initialize UI states
	if sun:
		$SettingsPanel/VBoxContainer/GridContainer/ShadowToggle.pressed = sun.shadow_enabled
	if day_night_system:
		$SettingsPanel/VBoxContainer/GridContainer/DayNightToggle.pressed = day_night_system.is_processing()

func _on_setup_pressed():
	panel.visible = !panel.visible

func _on_close_pressed():
	panel.hide()

func _on_shadow_toggled(button_pressed):
	if sun:
		sun.shadow_enabled = button_pressed

func _on_day_night_toggled(button_pressed):
	if day_night_system:
		day_night_system.set_process(button_pressed)

func _apply_water_drops(root_node):
	var shader_res = load("res://shaders/water_drop.shader")
	if shader_res:
		_recursive_water_drop(root_node, shader_res)

func _recursive_water_drop(node, shader_res):
	# NO aplicar a elementos críticos de lectura o controles complejos
	if node is Label or node is CheckButton or node is CheckBox:
		return
		
	if node.name == "SettingsPanel":
		for child in node.get_children():
			_recursive_water_drop(child, shader_res)
		return

	# Solo aplicar a botones normales o piezas de joystick (Panel)
	if node is Button or node is Panel:
		var mat = ShaderMaterial.new()
		mat.shader = shader_res
		node.material = mat
	
	for child in node.get_children():
		_recursive_water_drop(child, shader_res)
