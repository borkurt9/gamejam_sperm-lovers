extends Area3D
## Attracts sperm enemies toward this location when they enter
## Attach this script to: Elevator_final/button/Attraction

func _ready() -> void:
	add_to_group("attraction_toilet")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	print("[AttractionTrigger] Initialized at ", global_position)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("sperm") and body.has_method("start_attraction_to_toilet"):
		body.start_attraction_to_toilet()
		print("[AttractionTrigger] Sperm ", body.name, " entered - starting attraction")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("sperm") and body.has_method("stop_attraction_to_toilet"):
		# Optional: you might want to keep them attracted even after exiting
		# body.stop_attraction_to_toilet()
		print("[AttractionTrigger] Sperm ", body.name, " exited attraction zone")
