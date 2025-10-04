extends CharacterBody3D

@onready var camera = %Camera3D
@onready var grab_ray: RayCast3D = $Camera3D/GrabRay
@onready var hold_position: Node3D = $Camera3D/HoldPosition

var rotating: bool = false
var previous_mouse_position: Vector2

@export var rotation_speed_degrees: float = 90.0 #degrees per second

# Adjustable distances and movement strength
@export var hold_distance: float = 4.0
@export var hold_distance_min: float = 1.0
@export var hold_distance_max: float = 6.0
@export var scroll_sensitivity: float = 0.5
@export var attraction_force: float = 30.0
@export var max_pickup_distance: float = 8.0

# State tracking
var held_object: RigidBody3D = null

var _sun_level = 5.0 #should only be modified through intermediate functions
const _sun_level_max = 10 #we should choose a max sun level
const _sun_level_min = 0
var in_sunlight = false
const sun_charge_per_sec= 1.0
const sun_decay_per_second = -0.2

signal sun_level_changed(new_level: float)

func _ready():
	grab_ray.target_position.z = -max_pickup_distance
	grab_ray.enabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")

func _input(event):
	if held_object and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			hold_distance = clamp(hold_distance - scroll_sensitivity, hold_distance_min, hold_distance_max)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			hold_distance = clamp(hold_distance + scroll_sensitivity, hold_distance_min, hold_distance_max)

	# rotation
func rotate_held_object(_delta):
	if not held_object:
		return
	
	var rotation = Vector3.ZERO
	
	if Input.is_action_pressed("rotate_left"):
		rotation.y += 1
	if Input.is_action_pressed("rotate_right"):
		rotation.y -= 1
	if Input.is_action_pressed("rotate_up"):
		rotation.x += 1
	if Input.is_action_pressed("rotate_down"):
		rotation.x -= 1
	if Input.is_action_pressed("rotate_roll_left"):
		rotation.z += 1
	if Input.is_action_pressed("rotate_roll_right"):
		rotation.z -= 1
	
	if rotation != Vector3.ZERO:
		# Convert to radians
		var rotation_speed = deg_to_rad(rotation_speed_degrees)
		var rotation_radians = rotation * rotation_speed * _delta
		
		var basis = held_object.global_transform.basis
		basis = basis.rotated(Vector3.RIGHT, rotation_radians.x)
		basis = basis.rotated(Vector3.UP, rotation_radians.y)
		basis = basis.rotated(Vector3.BACK, rotation_radians.z)
		held_object.global_transform.basis = basis.orthonormalized()

func update_hold_position():
# Always position hold point in front of camera
	var forward = -camera.global_transform.basis.z
	hold_position.global_transform.origin = camera.global_transform.origin + forward * hold_distance

func try_grab_object():
	grab_ray.force_raycast_update()
	if grab_ray.is_colliding():
		var target = grab_ray.get_collider()
		if target is RigidBody3D:
			held_object = target
			held_object.gravity_scale = 0.0
			held_object.linear_damp = 10
			held_object.angular_damp = 10

func release_object():
	if held_object:
		held_object.gravity_scale = 5.0
		held_object = null

func move_held_object(_delta):
	var target_pos = hold_position.global_transform.origin
	var current_pos = held_object.global_transform.origin
	var direction = target_pos - current_pos
	var force = direction * attraction_force
	held_object.apply_central_force(force)

# camera movement
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
	
		# magnet grabbing
	update_hold_position()
	if Input.is_action_just_pressed("gravity_grab"):
		if held_object:
			release_object()
		else:
			try_grab_object()
	if held_object:
		move_held_object(delta)
		rotate_held_object(delta)
	
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
