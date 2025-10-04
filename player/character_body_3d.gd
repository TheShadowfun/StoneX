extends CharacterBody3D

@onready var camera = %Camera3D

var _sun_level = 5.0 #should only be modified through intermediate functions
const _sun_level_max = 10 #we should choose a max sun level
const _sun_level_min = 0
var in_sunlight = false
const sun_charge_per_sec= 1.0
const sun_decay_per_second = -0.2

signal sun_level_changed(new_level: float)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x  * 0.5
		camera.rotation_degrees.x -= event.relative.y * 0.5
		camera.rotation_degrees.x = clamp(
			camera.rotation_degrees.x, -60.0, 80.0
		)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

#Should usually take a positive argument, but can also take neg
func modify_sun_level(change):
	_sun_level = clamp(_sun_level + change, _sun_level_min, _sun_level_max)
	emit_signal("sun_level_changed", _sun_level)
	

func _physics_process(delta):
	const SPEED = 5.5
	
	var input_direction_2D = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	var input_direction_3D = Vector3(
		input_direction_2D.x, 0.0, input_direction_2D.y
	)
	var direction = transform.basis * input_direction_3D
	
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	
	velocity.y -= 20.0 * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 10
	elif Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y = 0.0
	
	move_and_slide()
	
	if in_sunlight:
		var sun_this_frame = sun_charge_per_sec * delta
		modify_sun_level(sun_this_frame)

	if not in_sunlight:
		var sun_this_frame = sun_decay_per_second * delta
		modify_sun_level(sun_this_frame)
