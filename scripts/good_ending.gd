extends Area3D

# Dialogue configuration
@export var dialogue_canvas_path: NodePath

## Path to the ending video scene
@export_file("*.tscn") var ending_video_scene: String = "res://scenes/ui/good_ending_video_player.tscn"

# First interaction: auto-chain dialogue
@export_group("Auto-Chain Dialogue")
@export var auto_chain_start_id: String = "GoodEnding_Egg"

var first_interaction_done = false
var checkPlayer = false
var just_closed_dialogue: bool = false

var dialogue_canvas

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if dialogue_canvas_path:
		var canvas_layer = get_node(dialogue_canvas_path)
		if canvas_layer:
			dialogue_canvas = canvas_layer.get_node("ControlNode")
			if not dialogue_canvas:
				push_warning("Control node not found in DialogueCanvas!")
		else: push_warning("DialogueCanvas not found at path: " + str(dialogue_canvas_path))
	else: push_warning("DialogueCanvas path not assigned!")


func _on_body_entered(body):
	if body.is_in_group("player"):
		checkPlayer = true


func _on_body_exited(body):
	if body.is_in_group("player"):
		checkPlayer = false


func _process(_delta):
	if just_closed_dialogue:
		just_closed_dialogue = false
		return

	if checkPlayer and Input.is_action_just_pressed("shoot"):
		interact()


func interact():
	if not dialogue_canvas:
		push_warning("DialogueCanvas reference not set!")
		return

	# Only auto-chain first interaction
	if not first_interaction_done and auto_chain_start_id != "":
		first_interaction_done = true
		dialogue_canvas.start_dialogue(auto_chain_start_id)
		dialogue_canvas.dialogue_finished.connect(_on_auto_chain_finished, CONNECT_ONE_SHOT)


func _on_auto_chain_finished():
	print("Good ending dialogue finished")
	just_closed_dialogue = true

	# Transition to the good ending video
	if ending_video_scene != "":
		print("Playing good ending video...")
		get_tree().change_scene_to_file(ending_video_scene)
