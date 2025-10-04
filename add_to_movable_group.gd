extends RigidBody3D

@onready var timer = $Timer
@export var pulse_speed: float = 1.75
@export var pulse_intensity: float = 0.5
@export var base_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var glow_color: Color = Color(1.0, 0.3, 0.3, 1.0)

var _is_glowing: bool = false
var _time: float = 0.0
var _original_materials = []
var _material_overrides = []

func _ready():
	add_to_group("movable")
	# Store original materials for all mesh instances
	if !has_node("Timer"):
		timer = Timer.new()
		timer.name = "Timer"
		add_child(timer)
	
	for child in get_children():
		if child is MeshInstance3D:
			var mesh_instance = child as MeshInstance3D
			_original_materials.append(mesh_instance.get_surface_override_material(0))
			
			# Create material override for glowing
			var material = mesh_instance.get_surface_override_material(0)
			if material == null:
				material = StandardMaterial3D.new()
			
			var glow_material = material.duplicate()
			_material_overrides.append(glow_material)

func _physics_process(delta: float) -> void:
	if _is_glowing:
		_time += delta * pulse_speed
		var pulse_factor = (sin(_time * 3.0) + 1.0) * 0.5 * pulse_intensity
		
		# Apply pulsing red color to all mesh instances
		var i = 0
		for child in get_children():
			if child is MeshInstance3D and i < _material_overrides.size():
				var material = _material_overrides[i]
				if material is StandardMaterial3D:
					# Blend between base color and glow color based on pulse factor
					material.albedo_color = base_color.lerp(glow_color, pulse_factor)
				child.set_surface_override_material(0, material)
				i += 1

func start_glowing() -> void:
	if not _is_glowing:
		_is_glowing = true
		_time = 0.0
		timer.start(2.3)  # Auto-stop glowing after 2.3 seconds
		timer.connect("timeout", Callable(self, "stop_glowing"), CONNECT_ONE_SHOT)

func stop_glowing() -> void:
	_is_glowing = false
	
	# Restore original materials
	var i = 0
	for child in get_children():
		if child is MeshInstance3D and i < _original_materials.size():
			child.set_surface_override_material(0, _original_materials[i])
			i += 1

func is_glowing() -> bool:
	return _is_glowing
