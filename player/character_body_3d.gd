extends CharacterBody3D

@onready var camera = %Camera3D
@onready var grab_ray: RayCast3D = $Camera3D/GrabRay
@onready var hold_position: Node3D = $Camera3D/HoldPosition

# Track previous camera transform for rotation calculations
var previous_camera_transform: Transform3D

@export var rotation_speed_degrees: float = 90.0 #degrees per second

# Adjustable distances and movement strength
@export var hold_distance: float = 4.0
@export var hold_distance_min: float = 2.5
@export var hold_distance_max: float = 6.0
@export var scroll_sensitivity: float = 0.5
@export var attraction_force: float = 30.0
@export var max_pickup_distance: float = 8.0

var held_object_original_layers: int = 0
var held_object_original_masks: int = 0

# State tracking
var held_object: RigidBody3D = null
var highlighting_interactable = false
var interactable = null


var _sun_level = 5.0 #should only be modified through intermediate functions
const _sun_level_max = 10 #we should choose a max sun level
const _sun_level_min = 0
var in_sunlight = false
const sun_charge_per_sec= 1.0
const sun_decay_per_second = -0.2

signal sun_level_changed(new_level: float)
signal button_pressed()

func _ready():
	grab_ray.target_position.z = -max_pickup_distance
	grab_ray.enabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	
	# Initialize previous camera transform
	previous_camera_transform = camera.global_transform

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
		
		var camera_basis = camera.global_transform.basis
		
		# Create rotation matrices around camera axes
		var object_basis = held_object.global_transform.basis
		 
		if rotation_radians.x != 0:
			object_basis = object_basis.rotated(camera_basis.x, rotation_radians.x)
		if rotation_radians.y != 0:
			object_basis = object_basis.rotated(camera_basis.y, rotation_radians.y)
		if rotation_radians.z != 0:
			object_basis = object_basis.rotated(camera_basis.z, rotation_radians.z)
			
		held_object.global_transform.basis = object_basis.orthonormalized()

# Apply camera rotation to held object to maintain relative orientation
func apply_camera_rotation_to_held_object():
	# Calculate the rotation change between the previous and current camera transform
	var prev_basis = previous_camera_transform.basis
	var current_basis = camera.global_transform.basis
	# Create a transformation that represents the camera's rotation change
	var rotation_change = prev_basis.inverse() * current_basis
	# Apply this rotation to the held object to maintain its orientation relative to camera
	held_object.global_transform.basis = rotation_change * held_object.global_transform.basis

func update_hold_position():
	# Always position hold point in front of camera
	var forward = -camera.global_transform.basis.z
	hold_position.global_transform.origin = camera.global_transform.origin + forward * hold_distance

func release_object():
	if held_object:
		held_object.gravity_scale = 5.0
		held_object.collision_layer = held_object_original_layers
		held_object.collision_mask = held_object_original_masks
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
		rotation_degrees.y -= event.relative.x  * 0.2
		camera.rotation_degrees.x -= event.relative.y * 0.2
		camera.rotation_degrees.x = clamp(
			camera.rotation_degrees.x, -60.0, 80.0
		)
	
#Should usually take a positive argument, but can also take neg
func modify_sun_level(change):
	_sun_level = clamp(_sun_level + change, _sun_level_min, _sun_level_max)
	emit_signal("sun_level_changed", _sun_level)
	
func detect_interactables():
	grab_ray.force_raycast_update()
	if grab_ray.is_colliding():
		var target = grab_ray.get_collider()
		if target.is_in_group("button") and Input.is_action_just_pressed("ui_accept"):
			emit_signal("button_pressed")
			return
		
		if target.is_in_group("movable"):
			if Input.is_action_just_pressed("gravity_grab"):
				held_object = target
				held_object_original_layers = held_object.collision_layer
				held_object_original_masks = held_object.collision_mask
				held_object.collision_layer = 2  #Set object to different collision layer, which player isn't on
				held_object.collision_mask = 2
				held_object.gravity_scale = 0.0
				held_object.linear_damp = 10
				held_object.angular_damp = 10
				
			elif not target.is_glowing():
				target.start_glowing()
		
func _physics_process(delta):
	const SPEED = 3.5
	
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
			
	if held_object:
		move_held_object(delta)
		rotate_held_object(delta)
		apply_camera_rotation_to_held_object()
		
		if Input.is_action_just_pressed("gravity_grab"):
			release_object()
	
	detect_interactables()
	
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
	
	# Store the current camera transform for the next frame
	previous_camera_transform = camera.global_transform
