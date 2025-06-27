extends RayCast3D

func _physics_process(delta: float) -> void:
	if is_colliding():
		var hit = get_collider()
		if hit.name == "hinge" and Input.is_action_just_pressed("interact"):
			var door_node = hit.get_parent().get_parent()
			if "toggle_door" in door_node:
				door_node.toggle_door()
