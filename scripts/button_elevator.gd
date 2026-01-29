extends Node3D
## Interactive elevator button that validates the elevator zone
## Changes light color based on validation result (green = valid, red = invalid)

# Node References
@onready var light: OmniLight3D = $OmniLight3D
@onready var interact_area: Area3D = $InteractableArea

# State
var player_in_range: bool = false
var elevator_zone: Area3D = null

# Signal for parent / other nodes to react when button is pressed + validation result
signal button_pressed_and_validated(is_valid: bool, enemy_count: int, has_player: bool)

func _ready() -> void:
	add_to_group("elevator_button")
	
	if interact_area:
		interact_area.body_entered.connect(_on_interact_area_entered)
		interact_area.body_exited.connect(_on_interact_area_exited)
	
	_find_elevator_zone()
	_set_light_color(false)  # start invalid/red
	
	print("[ElevatorButton] Initialized at ", global_position)

func _find_elevator_zone() -> void:
	var zones = get_tree().get_nodes_in_group("elevator_zone")
	if zones.size() > 0:
		elevator_zone = zones[0] as Area3D
		print("[ElevatorButton] Found elevator zone: ", elevator_zone.name)
	else:
		push_warning("[ElevatorButton] No elevator zone found in scene!")

func _on_interact_area_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		print("[ElevatorButton] Player entered interaction range")

func _on_interact_area_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		print("[ElevatorButton] Player left interaction range")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and player_in_range:
		_on_button_pressed()

func _on_button_pressed() -> void:
	print("[ElevatorButton] Button pressed!")
	
	if not elevator_zone:
		_find_elevator_zone()
	
	if not elevator_zone:
		print("[ElevatorButton] ERROR: No elevator zone found!")
		_set_light_color(false)
		button_pressed_and_validated.emit(false, 0, false)
		return
	
	var is_valid   = elevator_zone.validate()
	var enemy_count = elevator_zone.get_enemy_count()
	var has_player  = elevator_zone.has_player()
	
	_set_light_color(is_valid)
	button_pressed_and_validated.emit(is_valid, enemy_count, has_player)
	
	if is_valid:
		print("[ElevatorButton] ✓ VALID - Player only, elevator ready!")
	else:
		if not has_player: print("[ElevatorButton] ✗ FAILED - No player in zone")
		else: print("[ElevatorButton] ✗ FAILED - ", enemy_count, " enemies in zone")

func _set_light_color(is_valid: bool) -> void:
	if not light: return
	
	if is_valid:
		light.light_color = Color("#00ff00")  # Green
		print("[ElevatorButton] Light → GREEN")
	else:
		light.light_color = Color("#ff0000")  # Red
		print("[ElevatorButton] Light → RED")

## Optional: can be called externally (e.g. via signal) to re-check without pressing
func validate_zone() -> void:
	if elevator_zone:
		var is_valid = elevator_zone.validate()
		_set_light_color(is_valid)
