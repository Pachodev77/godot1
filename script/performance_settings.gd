extends CanvasLayer

onready var panel = $SettingsPanel
onready var setup_button = $SetupButton

# Nodes to control
var sun: DirectionalLight
var day_night_system: Spatial

func _ready():
	print("Performance Settings Ready")
	panel.hide()
	setup_button.connect("pressed", self, "_on_setup_pressed")
	print("Connected Setup Button")
	
	# Connect toggles
	$SettingsPanel/VBoxContainer/GridContainer/ShadowToggle.connect("toggled", self, "_on_shadow_toggled")
	$SettingsPanel/VBoxContainer/GridContainer/StarsToggle.connect("toggled", self, "_on_day_night_toggled")
	$SettingsPanel/VBoxContainer/CloseButton.connect("pressed", self, "_on_close_pressed")
	
	# Find nodes
	sun = get_node_or_null("/root/Escena/DayNightSystem/DirectionalLight")
	day_night_system = get_node_or_null("/root/Escena/DayNightSystem")
	
	# Initialize UI states
	if sun:
		$SettingsPanel/VBoxContainer/GridContainer/ShadowToggle.pressed = sun.shadow_enabled
	if day_night_system:
		$SettingsPanel/VBoxContainer/GridContainer/StarsToggle.pressed = day_night_system.is_processing()

func _on_setup_pressed():
	panel.show()

func _on_close_pressed():
	panel.hide()

func _on_shadow_toggled(button_pressed):
	if sun:
		sun.shadow_enabled = button_pressed

func _on_day_night_toggled(button_pressed):
	if day_night_system:
		day_night_system.set_process(button_pressed)
