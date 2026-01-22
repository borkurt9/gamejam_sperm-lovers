extends CharacterBody3D

@export var move_speed: float = 1.5
@export var wander_range: float = 3.0
@export var health: int = 5
@export var detection_range: float = 8.0
@export var chase_speed: float = 4.0

var wander_target: Vector3
var home_position: Vector3
var current_target: Node3D = null
var is_chasing: bool = false


func _ready() -> void:
	home_position = global_position
	add_to_group("enemies")
	pick_new_wander_target()


func _physics_process(_delta: float) -> void:
	# Check for nearby targets (player or sibling sperm)
	detect_targets()

	if is_chasing and is_instance_valid(current_target):
		# CHASE state: move toward target at chase speed
		var direction = (current_target.global_position - global_position).normalized()
		direction.y = 0
		velocity = direction * chase_speed
	else:
		# PATROL state: wander around
		is_chasing = false
		current_target = null

		var direction = (wander_target - global_position).normalized()
		direction.y = 0
		velocity = direction * move_speed

		# Pick new target when close
		if global_position.distance_to(wander_target) < 0.5:
			pick_new_wander_target()

	move_and_slide()

	# Face movement direction
	if velocity.length() > 0.1:
		rotation.y = atan2(velocity.x, velocity.z)


func pick_new_wander_target() -> void:
	wander_target = Vector3(
		home_position.x + randf_range(-wander_range, wander_range),
		global_position.y,
		home_position.z + randf_range(-wander_range, wander_range)
	)


func detect_targets() -> void:
	var nearest_target: Node3D = null
	var nearest_distance: float = detection_range

	# Check for player
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < nearest_distance:
			nearest_distance = dist
			nearest_target = player

	# Check for sibling sperm (they're in "enemies" group but have "become_aggro" method)
	for entity in get_tree().get_nodes_in_group("enemies"):
		if entity == self:
			continue
		if not entity.has_method("become_aggro"):
			continue  # Skip other white blood cells
		var dist = global_position.distance_to(entity.global_position)
		if dist < nearest_distance:
			nearest_distance = dist
			nearest_target = entity

	if nearest_target:
		current_target = nearest_target
		is_chasing = true
	else:
		is_chasing = false
		current_target = null


func take_damage(amount: int) -> void:
	health -= amount
	print("White blood cell took ", amount, " damage! Health: ", health)
	if health <= 0:
		print("White blood cell died!")
		queue_free()
