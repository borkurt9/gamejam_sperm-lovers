extends CharacterBody3D

@export var move_speed: float = 1.5
@export var wander_range: float = 3.0
@export var max_health: int = 5
var health: int
@export var detection_range: float = 8.0
@export var chase_speed: float = 2.5
@export var attack_damage: int = 2
@export var knockback_force: float = 12.0
@export var attack_cooldown: float = 1.0
@export var stop_distance: float = 1.5
@export var separation_radius: float = 3.0
@export var separation_force: float = 2.0
@export var model_rotation_offset: float = -PI/2  # Offset to align model forward with movement

var wander_target: Vector3
var home_position: Vector3
var current_target: Node3D = null
var is_chasing: bool = false
var is_aggro: bool = false
var can_attack: bool = true

@onready var attack_hitbox: Area3D = $AttackHitbox
@onready var hp_bar: Node3D = $HPBar


func _ready() -> void:
	home_position = global_position
	health = max_health
	add_to_group("enemies")
	pick_new_wander_target()

	# Connect attack hitbox signal
	if attack_hitbox:
		attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)


func _physics_process(_delta: float) -> void:
	# Only chase if aggro (has been shot)
	if is_aggro:
		detect_targets()

	var base_velocity := Vector3.ZERO

	if is_aggro and is_chasing and is_instance_valid(current_target):
		# Use horizontal distance only (ignore Y height difference)
		var horizontal_diff = current_target.global_position - global_position
		horizontal_diff.y = 0
		var dist_to_target = horizontal_diff.length()

		# Only move if not within stop distance
		if dist_to_target > stop_distance:
			var direction = horizontal_diff.normalized()
			base_velocity = direction * chase_speed
	else:
		# PATROL state: wander around
		is_chasing = false
		current_target = null

		var direction = (wander_target - global_position).normalized()
		direction.y = 0
		base_velocity = direction * move_speed

		# Pick new target when close
		if global_position.distance_to(wander_target) < 0.5:
			pick_new_wander_target()

	# Add separation from other enemies
	var separation = get_separation_from_enemies()
	velocity = base_velocity + separation

	move_and_slide()

	# Face movement direction
	if velocity.length() > 0.1:
		rotation.y = atan2(velocity.x, velocity.z) + model_rotation_offset

	# Check for continuous attack while overlapping
	check_continuous_attack()


func pick_new_wander_target() -> void:
	wander_target = Vector3(
		home_position.x + randf_range(-wander_range, wander_range),
		global_position.y,
		home_position.z + randf_range(-wander_range, wander_range)
	)


func get_separation_from_enemies() -> Vector3:
	var separation := Vector3.ZERO

	for entity in get_tree().get_nodes_in_group("enemies"):
		if entity == self:
			continue

		# Use horizontal distance only
		var horizontal_diff = global_position - entity.global_position
		horizontal_diff.y = 0
		var dist = horizontal_diff.length()

		if dist < separation_radius and dist > 0.01:
			var away_dir = horizontal_diff.normalized()
			# Stronger push when closer
			separation += away_dir * (separation_force * (1.0 - dist / separation_radius))

	return separation


func detect_targets() -> void:
	# Only target the player
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var horizontal_diff = player.global_position - global_position
		horizontal_diff.y = 0
		var dist = horizontal_diff.length()
		if dist < detection_range:
			current_target = player
			is_chasing = true
			return

	is_chasing = false
	current_target = null


func take_damage(amount: int) -> bool:
	health -= amount
	print("White blood cell took ", amount, " damage! Health: ", health)

	if hp_bar:
		hp_bar.update_health(health, max_health)

	# Become aggro when shot
	if not is_aggro:
		become_aggro()

	if health <= 0:
		print("White blood cell died!")
		queue_free()
		return true
	return false


func become_aggro(_target: Node3D = null) -> void:
	# Note: WBC ignores target parameter - always targets player
	if is_aggro:
		return
	is_aggro = true
	print("White blood cell became aggro!")


func _on_attack_hitbox_body_entered(body: Node3D) -> void:
	if not is_aggro:
		return
	if not can_attack:
		return
	if not body.is_in_group("player"):
		return
	if not body.has_method("take_damage"):
		return

	body.take_damage(attack_damage, global_position)
	can_attack = false
	get_tree().create_timer(attack_cooldown).timeout.connect(_reset_attack)


func _reset_attack() -> void:
	can_attack = true


func check_continuous_attack() -> void:
	if not is_aggro or not can_attack or not attack_hitbox:
		return
	for body in attack_hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(attack_damage, global_position)
			can_attack = false
			get_tree().create_timer(attack_cooldown).timeout.connect(_reset_attack)
			break
