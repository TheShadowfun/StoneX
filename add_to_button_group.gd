extends RigidBody3D

@onready var player = %Player

func _ready() -> void:
	add_to_group("button") #for the deletable, remove this
	if player.has_signal("button_pressed"): #for button, remove this
		player.connect("button_pressed", Callable(self, "interact")) #for button, remove this

func interact(): #for button, remove this
	queue_free() #for button, remove this
