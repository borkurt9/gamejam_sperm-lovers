extends Node3D

# --- Configuration ---
@export var sibling_scene: PackedScene
@export var spawn_on_start: bool = true
@export var spawn_check_radius: float = 0.5  # Reduced radius for closer spawning
@export var respawn_enabled: bool = true
@export var respawn_delay: float = 3.0  # Seconds before respawn
@export var spawn_spread_radius: float = 2.0  # Random offset applied to spawn positions
@export var attraction_start_delay: float = 0.5  # Delay before attraction starts (for spreading)

# --- Tracking ---
var active_siblings: Array[Node] = []
var marker_spawn_positions: Array[Vector3] = []  # All marker positions for respawning

# --- Node References ---
@onready var markers_parent: Node3D = get_node_or_null("Markers")

func _ready() -> void:
	if spawn_on_start:
		spawn_all_siblings()

func spawn_all_siblings() -> void:
	if not sibling_scene:
		print("MapManager Error: No sibling scene assigned!")
		return

	# Collect all markers in the scene
	var markers = []
	
	if markers_parent:
		markers = markers_parent.get_children()
	else:
		for child in get_tree().current_scene.find_children("*", "Marker3D"):
			markers.append(child)

	if markers.size() == 0:
		print("MapManager Warning: No markers found to spawn siblings.")
		return

	# Shuffle markers to prevent bias
	markers.shuffle()
	
	# Track spawned positions to avoid stacking
	var spawned_positions: Array[Vector3] = []
	
	# Loop through markers and instance siblings
	for marker in markers:
		if marker is Marker3D:
			# Use marker position directly - markers should be placed at correct height in editor
			var spawn_pos = marker.global_position

			# Store marker position for respawning
			marker_spawn_positions.append(spawn_pos)

			# Only check if position is too close to existing ones
			var too_close = false
			for existing_pos in spawned_positions:
				var distance = spawn_pos.distance_to(existing_pos)
				if distance < spawn_check_radius:
					too_close = true
					break

			if not too_close:
				spawn_sibling_at_position(spawn_pos)
				spawned_positions.append(spawn_pos)
				print("Spawned sibling at: ", marker.name)
			else:
				print("Skipped marker ", marker.name, " - too close to existing spawn")

func spawn_sibling_at_position(spawn_pos: Vector3) -> void:
	if not sibling_scene:
		return

	var new_sibling = sibling_scene.instantiate()

	# Add random offset to spread siblings apart
	var offset = Vector3(
		randf_range(-spawn_spread_radius, spawn_spread_radius),
		0,
		randf_range(-spawn_spread_radius, spawn_spread_radius)
	)
	var final_spawn_pos = spawn_pos + offset

	# Check if too close to existing active siblings, try to find better position
	var attempts = 0
	while _is_too_close_to_siblings(final_spawn_pos) and attempts < 5:
		offset = Vector3(
			randf_range(-spawn_spread_radius, spawn_spread_radius),
			0,
			randf_range(-spawn_spread_radius, spawn_spread_radius)
		)
		final_spawn_pos = spawn_pos + offset
		attempts += 1

	# Add to scene
	get_tree().current_scene.add_child(new_sibling)
	new_sibling.global_position = final_spawn_pos

	# Track this sibling
	active_siblings.append(new_sibling)

	# Ensure the enemy is part of the "enemies" group
	new_sibling.add_to_group("enemies")

	# Connect signals if needed (check if the sibling has these signals first)
	if new_sibling.has_signal("died"):
		new_sibling.died.connect(_handle_sibling_died.bind(new_sibling))

	# Always connect tree_exited for cleanup
	new_sibling.tree_exited.connect(_handle_sibling_removed.bind(new_sibling))

	# Start attraction to toilet after a short delay to let them spread out first
	if new_sibling.has_method("start_attraction_to_toilet"):
		_delayed_start_attraction(new_sibling)

func _is_too_close_to_siblings(pos: Vector3) -> bool:
	for sibling in active_siblings:
		if is_instance_valid(sibling):
			var dist = pos.distance_to(sibling.global_position)
			if dist < spawn_check_radius * 2:  # Use 2x check radius for respawn spacing
				return true
	return false

func _delayed_start_attraction(sibling: Node) -> void:
	await get_tree().create_timer(attraction_start_delay).timeout
	if is_instance_valid(sibling) and sibling.has_method("start_attraction_to_toilet"):
		sibling.start_attraction_to_toilet()

func clear_map() -> void:
	for sibling in active_siblings:
		if is_instance_valid(sibling):
			sibling.queue_free()
	active_siblings.clear()

func get_active_count() -> int:
	# Clean up invalid references and return count
	active_siblings = active_siblings.filter(func(s): return is_instance_valid(s))
	return active_siblings.size()

# Signal handler for sibling death
func _handle_sibling_died(sibling: Node) -> void:
	print("Sibling died: ", sibling.name if sibling else "Unknown")
	var spawn_pos = sibling.global_position if sibling else Vector3.ZERO
	active_siblings.erase(sibling)

	# Schedule respawn after delay
	if respawn_enabled and spawn_pos != Vector3.ZERO:
		_schedule_respawn(spawn_pos)

# Signal handler for sibling removal
func _handle_sibling_removed(sibling: Node) -> void:
	print("Sibling removed from tree: ", sibling.name if sibling else "Unknown")
	active_siblings.erase(sibling)

func _schedule_respawn(spawn_pos: Vector3) -> void:
	print("Scheduling respawn in ", respawn_delay, " seconds at ", spawn_pos)
	await get_tree().create_timer(respawn_delay).timeout

	if not respawn_enabled:
		print("Respawn cancelled - respawning disabled")
		return

	# Find closest marker position to use for respawn
	var respawn_position = _get_random_marker_position()
	if respawn_position != Vector3.ZERO:
		spawn_sibling_at_position(respawn_position)
		print("Respawned sibling at marker position")

func _get_random_marker_position() -> Vector3:
	if marker_spawn_positions.is_empty():
		return Vector3.ZERO
	return marker_spawn_positions.pick_random()

func disable_respawn() -> void:
	respawn_enabled = false
	print("Respawning disabled")

func enable_respawn() -> void:
	respawn_enabled = true
	print("Respawning enabled")
