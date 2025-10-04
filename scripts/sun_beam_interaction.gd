extends Area3D

var current_player: Node = null

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("Player entered sun ray")
		current_player = body
		current_player.in_sunlight = true

func _on_body_exited(body: Node) -> void:
	if body == current_player:
		print("Player exited sun ray, new sun level is " + str(current_player._sun_level))
		current_player.in_sunlight = false
		current_player = null
