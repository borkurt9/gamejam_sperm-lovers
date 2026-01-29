extends CharacterBody3D

const DeathSplash = preload("res://scenes/effects/death_splash.tscn")

# Signals
signal died()  # For MapManager respawn system

# Exports
@export var static_mode: bool = false
@export var move_speed: float = 2.0
@export var wander_range: float = 5.0
@export var max_health: int = 3
@export var detection_range: float = 10.0
@export var chase_speed: float = 3.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.5
@export var stop_distance: float = 1.2
@export var separation_radius: float = 2.0
@export var separation_force: float = 1.5
@export var model_rotation_offset: float = -PI/2

@export var wake_on_violence_range: float = 12.0
@export var casual_talk_block: String = "SpermDialogs"
@export var talk_max_distance: float = 4.5

@export var attraction_speed: float = 4.0
@export var attraction_stop_distance: float = 0.6

# State
var health: int
var wander_target: Vector3
var home_position: Vector3
var current_target: Node3D = null
var is_chasing: bool = false
var is_aggro: bool = false
var is_active: bool = true
var can_attack: bool = true
var wander_stuck_timer: float = 0.0
var last_position: Vector3

var player_in_hitbox: bool = false
var is_dead: bool = false

# Attraction (only to toilet zone)
var toilet_attraction_position: Vector3 = Vector3.ZERO
var is_attracted_to_toilet: bool = false

# Nodes
@onready var attack_hitbox: Area3D = $AttackHitbox
@onready var hp_bar: Node3D = $HPBar
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var dialog_system: Control = $DialogSystem/ControlNode

func _ready() -> void:
	home_position = global_position
	last_position = global_position
	health = max_health
	
	add_to_group("enemies")
	add_to_group("sperm")
	
	if attack_hitbox:
		attack_hitbox.body_entered.connect(_on_hitbox_body_entered)
		attack_hitbox.body_exited.connect(_on_hitbox_body_exited)
	
	_find_toilet_attraction_target()
	
	if not static_mode:
		pick_new_wander_target()
	
	# Give nav agent time to initialize
	await get_tree().physics_frame
	await get_tree().physics_frame

func _find_toilet_attraction_target() -> void:
	# Try multiple methods to find the attraction target
	
	# Method 1: Check for nodes in "attraction_toilet" group
	var candidates = get_tree().get_nodes_in_group("attraction_toilet")
	if not candidates.is_empty():
		var candidate = candidates[0]
		if candidate is Node3D:
			toilet_attraction_position = candidate.global_position
			print("[Sperm] Found attraction via group: ", candidate.name, " at ", toilet_attraction_position)
			return
		elif candidate.get_parent() is Node3D:
			toilet_attraction_position = candidate.get_parent().global_position
			print("[Sperm] Found attraction via group parent: ", candidate.get_parent().name, " at ", toilet_attraction_position)
			return
	
	# Method 2: Search for Attraction node by path pattern
	var root = get_tree().current_scene
	for node in _find_all_nodes(root):
		if node.name == "Attraction" and node is Area3D:
			toilet_attraction_position = node.global_position
			print("[Sperm] Found Attraction node at: ", toilet_attraction_position)
			return
	
	# Method 3: Hardcoded fallback to known coordinates
	toilet_attraction_position = Vector3(16.0, 0.8, -7.0)
	print("[Sperm] Using hardcoded attraction position: ", toilet_attraction_position)

func _find_all_nodes(node: Node) -> Array[Node]:
	var result: Array[Node] = [node]
	for child in node.get_children():
		result.append_array(_find_all_nodes(child))
	return result

func _physics_process(delta: float) -> void:
	if not is_active or is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Priority: Attraction to toilet zone
	if is_attracted_to_toilet:
		_handle_toilet_attraction(delta)
		return

	# Static & peaceful → no movement
	if static_mode and not is_aggro:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	velocity = Vector3.ZERO  # default

	# Aggro mode: chase player
	if is_aggro:
		detect_targets()

		if is_chasing and is_instance_valid(current_target):
			nav_agent.target_position = current_target.global_position

			var dist = global_position.distance_to(current_target.global_position)

			# Always move toward player if not at attack range
			if dist > stop_distance:
				var next_pos = nav_agent.get_next_path_position()
				var dir = (next_pos - global_position).normalized()
				dir.y = 0

				if dir.length() > 0.01:
					velocity = dir * chase_speed
			else:
				# Within attack range - still move closer but slower for precise positioning
				var dir = (current_target.global_position - global_position).normalized()
				dir.y = 0
				if dir.length() > 0.01:
					velocity = dir * (chase_speed * 0.3)  # Move slower when in attack range

	# Peaceful wandering (only if not aggro and not static)
	elif not static_mode:
		var to_wander = wander_target - global_position
		to_wander.y = 0

		if to_wander.length() < 0.5:
			pick_new_wander_target()
		else:
			velocity = to_wander.normalized() * move_speed

		# Stuck detection
		var moved = global_position.distance_to(last_position)
		if moved < 0.05:
			wander_stuck_timer += delta
			if wander_stuck_timer > 2.0:
				pick_new_wander_target()
				wander_stuck_timer = 0.0
		else:
			wander_stuck_timer = 0.0
		last_position = global_position

	# Common post-movement logic
	_apply_separation()
	move_and_slide()
	_rotate_toward_movement()

	if is_aggro:
		check_continuous_attack()

func _handle_toilet_attraction(delta: float) -> void:
	var to_target = toilet_attraction_position - global_position
	to_target.y = 0
	
	if to_target.length() < attraction_stop_distance:
		is_attracted_to_toilet = false
		velocity = Vector3.ZERO
		print("[Sperm] Reached attraction target!")
		return
	
	var dir = to_target.normalized()
	velocity = dir * attraction_speed
	
	# Light separation during attraction
	velocity += get_separation_from_enemies() * 0.6
	
	move_and_slide()
	_rotate_toward_movement()

func _apply_separation() -> void:
	var push = Vector3.ZERO
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self: continue
		var diff = global_position - e.global_position
		diff.y = 0
		var d = diff.length()
		if d < separation_radius and d > 0.01:
			push += diff.normalized() * separation_force * (1.0 - d / separation_radius)
	velocity += push

func _rotate_toward_movement() -> void:
	if velocity.length() < 0.1: return
	var flat_vel = velocity
	flat_vel.y = 0
	if flat_vel.length() > 0.05:
		rotation.y = atan2(flat_vel.x, flat_vel.z) + model_rotation_offset

# Attraction control
func start_attraction_to_toilet() -> void:
	is_attracted_to_toilet = true
	is_aggro = false
	is_chasing = false
	current_target = null
	print("[Sperm] Started attraction to toilet at ", toilet_attraction_position)

func stop_attraction_to_toilet() -> void:
	is_attracted_to_toilet = false
	print("[Sperm] Stopped attraction to toilet")

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"): player_in_hitbox = true
func _on_hitbox_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"): player_in_hitbox = false

func pick_new_wander_target() -> void:
	var offset = Vector3(
		randf_range(-wander_range, wander_range),
		0,
		randf_range(-wander_range, wander_range)
	)
	wander_target = home_position + offset

func check_continuous_attack() -> void:
	if not is_aggro or not can_attack or not attack_hitbox: return
	
	for body in attack_hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(attack_damage, global_position)
			can_attack = false
			get_tree().create_timer(attack_cooldown).timeout.connect(_reset_attack)
			break

func _reset_attack() -> void:
	can_attack = true

func get_separation_from_enemies() -> Vector3:
	var push = Vector3.ZERO
	for entity in get_tree().get_nodes_in_group("enemies"):
		if entity == self: continue
		var diff = global_position - entity.global_position
		diff.y = 0
		var dist = diff.length()
		if dist < separation_radius and dist > 0.01:
			var dir = diff.normalized()
			push += dir * (separation_force * (1.0 - dist / separation_radius))
	return push

# Aggro / Damage / Death
func detect_targets() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		if global_position.distance_to(player.global_position) < detection_range:
			current_target = player
			is_chasing = true
			return
	current_target = null
	is_chasing = false

func become_aggro() -> void:
	if is_aggro: return
	is_aggro = true
	is_attracted_to_toilet = false
	print("[Sperm] Became aggro!")

func take_damage(amount: int) -> bool:
	health -= amount
	print("Sibling took ", amount, " damage! Health: ", health)
	if hp_bar: hp_bar.update_health(health, max_health)
	
	if not is_aggro: become_aggro()
	
	if health <= 0:
		die()
		return true
	return false

func die() -> void:
	if is_dead: return
	is_dead = true
	
	print("Sibling died!")
	died.emit()
	
	var splash = DeathSplash.instantiate()
	# Add your color setup here if needed
	get_tree().current_scene.add_child(splash)
	splash.global_position = global_position
	
	# Wake nearby enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != self and enemy.has_method("_on_nearby_violence"):
			enemy._on_nearby_violence(global_position)
	
	queue_free()

# Player interaction / dialog
func _input(event: InputEvent) -> void:
	if is_aggro: return
	if not player_in_hitbox: return
	if not dialog_system: return
	if Input.is_action_pressed("aim"): return
	
	if event.is_action_pressed("shoot"):
		get_viewport().set_input_as_handled()
		_trigger_dialogue()

func _trigger_dialogue() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var dist = global_position.distance_to(player.global_position)
	if dist > talk_max_distance: return
	
	dialog_system.start_dialogue(casual_talk_block, false)
	print("[Sperm] Player poked me → said: ", casual_talk_block)

func _on_nearby_violence(violence_position: Vector3) -> void:
	if is_aggro: return
	if global_position.distance_to(violence_position) < wake_on_violence_range:
		become_aggro()
