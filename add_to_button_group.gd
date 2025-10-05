extends CSGBox3D

@onready var player = %Player

func _ready() -> void:
	add_to_group("button") #for the deletable, remove this
