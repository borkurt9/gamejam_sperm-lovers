extends Node3D

@onready var label: Label3D = $Label3D

var is_done: bool = false

const NOT_DONE_TEXT: String = "?"
const DONE_TEXT: String = "OK"
const NOT_DONE_COLOR: Color = Color(1.0, 0.3, 0.3)  # Red
const DONE_COLOR: Color = Color(0.3, 1.0, 0.3)  # Green


func _ready() -> void:
	set_done(false)


func set_done(value: bool) -> void:
	is_done = value

	if label:
		if is_done:
			label.text = DONE_TEXT
			label.modulate = DONE_COLOR
		else:
			label.text = NOT_DONE_TEXT
			label.modulate = NOT_DONE_COLOR
