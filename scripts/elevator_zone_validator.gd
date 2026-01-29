extends Area3D

## Validates that only the player is inside the elevator zone
## Only tracks entities in "enemies" group
## Zone is valid when: player inside AND no enemies inside

# Signals
signal zone_status_changed(is_valid: bool, enemy_count: int)
signal player_entered()
signal player_exited()
signal enemy_entered(enemy: Node3D)
signal enemy_exited(enemy: Node3D)

# State
var enemies_inside: Array[Node3D] = []
var player_inside: Node3D = null

func _ready() -> void:
	add_to_group("elevator_zone")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	print("[ElevatorZone] Initialized - tracking 'enemies' group only")

func _on_body_entered(body: Node3D) -> void:
	# Track player
	if body.is_in_group("player"):
		player_inside = body
		player_entered.emit()
		print("[ElevatorZone] Player entered")
		_validate_zone()
		return
	
	# Track enemies only
	if body.is_in_group("enemies"):
		if not enemies_inside.has(body):
			enemies_inside.append(body)
			enemy_entered.emit(body)
			print("[ElevatorZone] Enemy entered: ", body.name, " (", enemies_inside.size(), " total)")
		_validate_zone()

func _on_body_exited(body: Node3D) -> void:
	# Check if player left
	if body.is_in_group("player") and body == player_inside:
		player_inside = null
		player_exited.emit()
		print("[ElevatorZone] Player exited")
		_validate_zone()
		return
	
	# Remove enemy
	if body.is_in_group("enemies"):
		if enemies_inside.has(body):
			enemies_inside.erase(body)
			enemy_exited.emit(body)
			print("[ElevatorZone] Enemy exited: ", body.name, " (", enemies_inside.size(), " remaining)")
		_validate_zone()

func _validate_zone() -> void:
	var is_valid = is_zone_valid()
	zone_status_changed.emit(is_valid, enemies_inside.size())
	
	if is_valid:
		print("[ElevatorZone] ✓ VALID - Player only, no enemies")
	else:
		if not player_inside: print("[ElevatorZone] ✗ INVALID - No player (", enemies_inside.size(), " enemies)")
		elif enemies_inside.size() > 0: print("[ElevatorZone] ✗ INVALID - ", enemies_inside.size(), " enemies present")

## Returns true only if player is inside AND no enemies are inside
func is_zone_valid() -> bool:
	return player_inside != null and enemies_inside.size() == 0

## Get current enemy count in zone
func get_enemy_count() -> int:
	return enemies_inside.size()

## Check if player is inside
func has_player() -> bool:
	return player_inside != null

## Check if any enemies are inside
func has_enemies() -> bool:
	return enemies_inside.size() > 0

## Manual validation trigger (for external calls)
func validate() -> bool:
	var is_valid = is_zone_valid()
	zone_status_changed.emit(is_valid, enemies_inside.size())
	return is_valid
