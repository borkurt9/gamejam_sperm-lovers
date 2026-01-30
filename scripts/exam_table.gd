extends Area3D

signal table_completed(table_id: int)

@export var problem_text: String = ""
@export var correct_answer: float = 0.0
@export var correct_answer_fraction: String = ""  # e.g. "50/3" for fraction answers
@export var tolerance: float = 0.01
@export var table_id: int = 1

@onready var progress_symbol: Node3D = $ProgressSymbol

var is_completed: bool = false
var player_in_range: bool = false
var player_ref: Node3D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		player_ref = body


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		player_ref = null


func _input(event: InputEvent) -> void:
	if is_completed or not player_in_range:
		return

	# Allow interaction via interact action or left click
	if event.is_action_pressed("interact") or event.is_action_pressed("shoot"):
		if player_ref and not player_ref.is_aiming:
			get_viewport().set_input_as_handled()
			_on_interact()


func _on_interact() -> void:
	# Find the blue book UI and show it with this table's problem
	var blue_book = get_tree().get_first_node_in_group("blue_book_ui")
	if blue_book and blue_book.has_method("show_book"):
		blue_book.show_book(self)


func check_answer(player_answer: String) -> bool:
	# Try to parse the answer
	var parsed_value: float = 0.0
	var answer_str = player_answer.strip_edges()

	# Check for fraction format (e.g., "50/3", "2/3")
	if "/" in answer_str:
		var parts = answer_str.split("/")
		if parts.size() == 2:
			var numerator = parts[0].strip_edges().to_float()
			var denominator = parts[1].strip_edges().to_float()
			if denominator != 0:
				parsed_value = numerator / denominator
			else:
				return false
	else:
		parsed_value = answer_str.to_float()

	# Check if answer matches within tolerance
	if abs(parsed_value - correct_answer) <= tolerance:
		return true

	# Also check if they entered the exact fraction string
	if correct_answer_fraction != "" and answer_str == correct_answer_fraction:
		return true

	return false


func mark_complete() -> void:
	if is_completed:
		return

	is_completed = true

	# Update the progress symbol
	if progress_symbol and progress_symbol.has_method("set_done"):
		progress_symbol.set_done(true)

	# Emit signal
	table_completed.emit(table_id)
	print("Table ", table_id, " completed!")
