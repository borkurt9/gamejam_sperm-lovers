extends CharacterBody3D

# Movement
@export var move_speed: float = 6.0

# Shooting
@export var bullet_scene: PackedScene
@onready var shooting_point: Node3D = $ShootingPoint

# Isometric direction conversion
# WASD maps to diagonal world directions
var iso_forward := Vector3(-1, 0, -1).normalized()
var iso_back := Vector3(1, 0, 1).normalized()
var iso_left := Vector3(-1, 0, 1).normalized()
var iso_right := Vector3(1, 0, -1).normalized()

var current_aim_direction := Vector3.FORWARD

func _physics_process(delta: float) -> void:
	handle_movement()
	handle_rotation()
	move_and_slide()

func handle_movement() -> void:
	var input_dir := Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		input_dir += iso_forward
	if Input.is_action_pressed("move_back"):
		input_dir += iso_back
	if Input.is_action_pressed("move_left"):
		input_dir += iso_left
	if Input.is_action_pressed("move_right"):
		input_dir += iso_right
	
	input_dir = input_dir.normalized()
	velocity.x = input_dir.x * move_speed
	velocity.z = input_dir.z * move_speed
	
	# Store direction for aiming
	if input_dir != Vector3.ZERO:
		current_aim_direction = input_dir


func handle_rotation() -> void:
	# Rotate player to face movement direction
	if velocity.length() > 0.1:
		var target_rotation := atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 0.2)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		shoot()


func shoot() -> void:
	if bullet_scene == null:
		print("No bullet scene assigned!")
		return
	
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position = shooting_point.global_position
	bullet.direction = current_aim_direction
	print("Bang!")
