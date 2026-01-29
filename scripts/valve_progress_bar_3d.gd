extends Node3D

## Radial progress bar for valves
## Shows circular progress with countdown timer in center

# Configuration
@export var fill_color: Color = Color(0.9, 0.8, 0.2, 1)  # Yellow
@export var complete_color: Color = Color(0.2, 0.9, 0.3, 1)  # Green
@export var bg_color: Color = Color(0.2, 0.2, 0.2, 0.8)  # Dark grey
@export var arc_width: float = 12.0

# State
var progress: float = 0.0
var fill_time: float = 10.0
var is_complete: bool = false

# Node references
@onready var sub_viewport: SubViewport = $SubViewport
@onready var radial_control: Control = $SubViewport/RadialProgress
@onready var time_label: Label = $SubViewport/RadialProgress/TimeLabel
@onready var sprite: Sprite3D = $Sprite3D

func _ready() -> void:
	# Initialize display
	_update_display()

func set_progress(value: float) -> void:
	progress = clamp(value, 0.0, 1.0)
	is_complete = progress >= 1.0
	_update_display()

func set_fill_time(time: float) -> void:
	fill_time = time
	_update_display()

func _update_display() -> void:
	if not is_inside_tree():
		return

	# Update time label
	if time_label:
		if is_complete:
			time_label.text = "OK"
		else:
			var remaining = fill_time * (1.0 - progress)
			time_label.text = "%.1f" % remaining

	# Trigger redraw on the control
	if radial_control:
		radial_control.queue_redraw()

# Called by RadialProgress control to get current state
func get_draw_progress() -> float:
	return progress

func get_draw_color() -> Color:
	return complete_color if is_complete else fill_color

func get_bg_color() -> Color:
	return bg_color

func get_arc_width() -> float:
	return arc_width
