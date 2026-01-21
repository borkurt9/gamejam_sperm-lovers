extends Area3D

@export var next_scene: PackedScene
var checkPlayer = false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		checkPlayer = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		checkPlayer = false

func _process(delta):
	if checkPlayer and Input.is_action_just_pressed("shoot"):
		if next_scene:
			get_tree().change_scene_to(next_scene)
		else:
			print("Next scene not set!")
