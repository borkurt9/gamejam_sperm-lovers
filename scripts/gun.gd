extends Node3D

var idle_position := Vector3(0.302, 0.678, 0.409)
var idle_rotation := Vector3(3.5, -10.7, 0.0)

@export var aim_position := Vector3(0.0, 0.5, 0.5)
@export var aim_rotation := Vector3(0.0, 0.0, 0.0)
@export var aim_speed := 15.0

# Recoil settings
@export var recoil_kickback := 0.10
@export var recoil_rotation := 50.0  # degrees
var recoil_offset := 0.0
var recoil_rot_offset := 0.0

@onready var player: CharacterBody3D = get_parent()

func _ready() -> void:
	position = idle_position
	rotation_degrees = idle_rotation

func _process(delta: float) -> void:
	var target_pos := aim_position if (player and player.is_aiming) else idle_position
	var target_rot := aim_rotation if (player and player.is_aiming) else idle_rotation
	
	# Apply recoil offset
	var current_target_pos = target_pos + Vector3(0, 0, recoil_offset)
	var current_target_rot = target_rot + Vector3(-recoil_rot_offset, 0, 0)
	
	position = position.lerp(current_target_pos, aim_speed * delta)
	rotation_degrees = rotation_degrees.lerp(current_target_rot, aim_speed * delta)
	
	# Decay recoil
	recoil_offset = lerpf(recoil_offset, 0.0, 10.0 * delta)
	recoil_rot_offset = lerpf(recoil_rot_offset, 0.0, 10.0 * delta)

func recoil() -> void:
	recoil_offset = recoil_kickback
	recoil_rot_offset = recoil_rotation
