extends Control

@onready var option_menu: TabContainer = $"../Settings"

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$VBoxContainer/Start.grab_focus()

func reset_focus():
	$VBoxContainer/Start.grab_focus()

func _on_start_pressed():
	Utilities.switch_scene("TestLevel", self)
	AudioManager.play_music_sound()

func _on_option_pressed():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	option_menu.show()
	option_menu.reset_focus()
	AudioManager.play_button_sound()

func _on_quit_pressed():
	get_tree().quit()
	
func _unhandled_input(event):
	# First, check if the event is one of the types we care about.
	# We are looking for mouse button presses or key presses.
	var is_left_mouse_press = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
	var is_enter_press = event is InputEventKey and event.keycode == KEY_ENTER and event.is_pressed()
	var is_space_press = event is InputEventKey and event.keycode == KEY_SPACE and event.is_pressed()

	# If the event is NOT one of our desired inputs, ignore it by returning early.
	if not (is_left_mouse_press or is_enter_press or is_space_press):
		return
