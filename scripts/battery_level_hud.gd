extends CanvasLayer

@onready var battery_bar = $Control/ProgressBar
@onready var player = %Player

func _ready() -> void:
	if player.has_signal("sun_level_changed"):
		player.connect("sun_level_changed", Callable(self, "_update_battery_bar"))
		_update_battery_bar(player._sun_level)

func _update_battery_bar(new_level):
	battery_bar.value = new_level
