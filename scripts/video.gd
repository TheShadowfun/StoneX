extends TabBar

@onready var vsync_check_box: CheckBox = $Vsync
@onready var fullscreen_check_box: CheckBox = $Fullscreen

const CONFIG_FILE_PATH = "user://settings.cfg"

func _ready():
	load_video_settings()

func load_video_settings():
	var config = ConfigFile.new()
	# Load the config file, or create a new one if it doesn't exist
	if config.load(CONFIG_FILE_PATH) != OK:
		config = ConfigFile.new()

	# Load VSync setting, default to true
	var vsync_enabled = config.get_value("video", "vsync", true)
	vsync_check_box.button_pressed = vsync_enabled
	_on_vsync_toggled(vsync_enabled)
	
	# Load Fullscreen setting, default to false
	var fullscreen_enabled = config.get_value("video", "fullscreen", false)
	fullscreen_check_box.button_pressed = fullscreen_enabled
	_on_fullscreen_toggled(fullscreen_enabled)

func save_setting(key: String, value):
	var config = ConfigFile.new()
	config.load(CONFIG_FILE_PATH) # Load existing to not overwrite other settings
	config.set_value("video", key, value)
	config.save(CONFIG_FILE_PATH)

func _on_vsync_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	save_setting("vsync", toggled_on)
	AudioManager.play_button_sound()

func _on_fullscreen_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_setting("fullscreen", toggled_on)
	AudioManager.play_button_sound()
