extends Node3D

@export var bar_color: Color = Color.GREEN
@export var background_color: Color = Color(0.2, 0.2, 0.2, 0.8)
@export var always_visible: bool = true
@export var hide_delay: float = 3.0

@onready var progress_bar: ProgressBar = $SubViewport/ProgressBar
@onready var sprite: Sprite3D = $Sprite3D

var hide_timer: float = 0.0


func _ready() -> void:
	setup_colors()
	if not always_visible:
		hide()


func _process(delta: float) -> void:
	if not always_visible and visible:
		hide_timer -= delta
		if hide_timer <= 0:
			hide()


func setup_colors() -> void:
	# Create custom StyleBoxFlat for fill
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	progress_bar.add_theme_stylebox_override("fill", fill_style)

	# Create custom StyleBoxFlat for background
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = background_color
	progress_bar.add_theme_stylebox_override("background", bg_style)


func update_health(current: int, maximum: int) -> void:
	progress_bar.max_value = maximum
	progress_bar.value = current

	if not always_visible:
		show()
		hide_timer = hide_delay
