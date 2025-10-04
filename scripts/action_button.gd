extends Button
class_name RemapButton

@export var action: String = "Up"

func _init():
	toggle_mode = true

func _ready():
	set_process_unhandled_input(false)
	display_key()

func _toggled(pressed: bool):
	set_process_unhandled_input(pressed)
	if pressed:
		text = "Press any key"
		release_focus()
	else:
		display_key()
		grab_focus()

func _unhandled_input(event: InputEvent):
	# Filter acceptable events
	if event is InputEventKey and event.pressed and not event.echo:
		apply_new_event(event)
	elif event is InputEventMouseButton and event.pressed:
		apply_new_event(event)
	elif event is InputEventJoypadButton and event.pressed:
		apply_new_event(event)
	# (Add more event types if you want)
	# Consume so it doesn't propagate
	get_viewport().set_input_as_handled()

func apply_new_event(event: InputEvent):
	if not InputMap.has_action(action):
		push_warning("Action '%s' does not exist; cannot remap." % action)
		button_pressed = false
		return
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	Utilities.config.set_value("Controls", action, event)
	Utilities.save_data()
	button_pressed = false  # triggers _toggled(false) -> display_key()

func display_key():
	if not InputMap.has_action(action):
		text = "<Missing>"
		return
	var events := InputMap.action_get_events(action)
	text = "<Unassigned>" if events.is_empty() else events[0].as_text()
