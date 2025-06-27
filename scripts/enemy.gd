extends CharacterBody3D

@export var patrol_destination: Array[Node3D]
@export var chase_radius: float = 8.0
@export var chase_lost_radius: float = 12.0
@export var speed: float = 2.0

@onready var player = get_tree().current_scene.get_node("player")
@onready var rng = RandomNumberGenerator.new()
@onready var nav_agent = $NavigationAgent3D
@onready var anim_player: AnimationPlayer = get_node("witch_walk/Armature/AnimationPlayer")

var destination_value: int
var destination: Node3D
var chasing: bool = false

func _ready() -> void:
	rng.randomize()
	pick_destination()

	if anim_player:
		print("✅ AnimationPlayer found.")
	else:
		print("❌ AnimationPlayer NOT found! Check node path.")

func _process(delta: float) -> void:
	update_behavior()
	rotate_toward_movement()
	handle_animation()

func _physics_process(delta: float) -> void:
	if destination:
		var current_location = global_transform.origin
		var next_location = nav_agent.get_next_path_position()
		var direction = (next_location - current_location).normalized()
		var new_velocity = direction * speed
		velocity = velocity.move_toward(new_velocity, 0.25)
		move_and_slide()

		if not chasing and current_location.distance_to(destination.global_transform.origin) < 1.0:
			pick_destination(destination_value)

func update_behavior():
	var distance_to_player = global_transform.origin.distance_to(player.global_transform.origin)

	if chasing:
		if distance_to_player > chase_lost_radius:
			chasing = false
			pick_destination()
		else:
			destination = player
	else:
		if distance_to_player < chase_radius:
			chasing = true
			destination = player

	update_target_location()

func update_target_location():
	if destination:
		if chasing:
			nav_agent.target_position = player.global_transform.origin
		else:
			nav_agent.target_position = destination.global_transform.origin

func pick_destination(dont_choose = null):
	if patrol_destination.size() == 0:
		return

	var num = rng.randi_range(0, patrol_destination.size() - 1)

	if dont_choose != null and patrol_destination.size() > 1:
		while num == dont_choose:
			num = rng.randi_range(0, patrol_destination.size() - 1)

	destination_value = num
	destination = patrol_destination[num]
	update_target_location()

func rotate_toward_movement():
	if velocity.length() > 0.1:
		var target_dir = atan2(-velocity.x, -velocity.z)
		var current_yaw = deg_to_rad(global_rotation_degrees.y)
		var new_yaw = lerp_angle(current_yaw, target_dir, 0.5)
		global_rotation_degrees.y = rad_to_deg(new_yaw)

func handle_animation():
	if anim_player == null:
		print("❌ anim_player is null!")
		return

	if velocity.length() > 0.1:
		if not anim_player.is_playing() or anim_player.current_animation != "Armature|Casual_Walk|baselayer":
			anim_player.play("Armature|Casual_Walk|baselayer")

# 🚨 This function must be connected to the DetectionArea's "body_entered" signal!
func _on_DetectionArea_body_entered(body: Node) -> void:
	print("Detected body:", body.name)
	if body.name == "player":
		get_tree().change_scene_to_file("res://scenery/end.tscn")
