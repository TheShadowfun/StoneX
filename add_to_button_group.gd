extends RigidBody3D

@onready var player = %Player

func _ready() -> void:
	add_to_group("button")
	if player.has_signal("sun_level_changed"):
		player.connect("button_pressed", Callable(self, "interact"))

func interact():
	queue_free()
