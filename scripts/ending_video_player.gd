extends Control

## Path to the video file to play
@export_file("*.ogv") var video_path: String = "res://endings/SecretEnding.ogv"

## Scene to transition to after video ends (optional - if empty, goes to main menu)
@export var next_scene_path: String = "res://scenes/menu_new.tscn"

## Allow skipping the video with any input after this many seconds
@export var skip_delay: float = 2.0

## Text to display after video (typewriter effect)
@export_multiline var ending_text: String = """SECRET ENDING UNLOCKED

You chose to leave the race behind.

While your siblings fought for glory,
you found peace in surrender.

Not every sperm reaches the egg.
Not every journey ends in victory.
But every choice has meaning.

Thank you for discovering this secret.

- The Sperm Sanity Team"""

## Typewriter speed (characters per second)
@export var typewriter_speed: float = 30.0

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var ending_label: Label = $EndingTextContainer/EndingLabel
@onready var ending_container: Control = $EndingTextContainer

var can_skip: bool = false
var video_finished: bool = false
var showing_text: bool = false
var text_finished: bool = false
var current_char_index: int = 0
var char_timer: float = 0.0


func _ready() -> void:
	# Hide mouse cursor during video
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Hide ending text initially
	ending_container.visible = false
	ending_label.text = ""
	
	# Load and play the video
	if video_path != "":
		var stream = load(video_path)
		if stream:
			video_player.stream = stream
			video_player.play()
		else:
			push_error("Failed to load video: " + video_path)
			_show_ending_text()
			return
	else:
		_show_ending_text()
		return
	
	# Connect finished signal
	video_player.finished.connect(_on_video_finished)
	
	# Enable skipping after delay
	await get_tree().create_timer(skip_delay).timeout
	can_skip = true


func _process(delta: float) -> void:
	# Typewriter effect
	if showing_text and not text_finished:
		char_timer += delta * typewriter_speed
		while char_timer >= 1.0 and current_char_index < ending_text.length():
			current_char_index += 1
			ending_label.text = ending_text.substr(0, current_char_index)
			char_timer -= 1.0
		
		if current_char_index >= ending_text.length():
			text_finished = true


func _input(event: InputEvent) -> void:
	# During video: allow skipping after delay
	if can_skip and not video_finished:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("shoot"):
			_on_video_finished()
			return
	
	# During text display
	if showing_text:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("shoot"):
			if not text_finished:
				# Skip to full text
				current_char_index = ending_text.length()
				ending_label.text = ending_text
				text_finished = true
			else:
				# Text is done, go to next scene
				_go_to_next_scene()


func _on_video_finished() -> void:
	if video_finished:
		return
	
	video_finished = true
	video_player.stop()
	video_player.visible = false
	
	# Show ending text with typewriter effect
	_show_ending_text()


func _show_ending_text() -> void:
	showing_text = true
	ending_container.visible = true
	ending_label.text = ""
	current_char_index = 0
	char_timer = 0.0
	
	# Show mouse cursor for the text screen
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _go_to_next_scene() -> void:
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
	else:
		get_tree().change_scene_to_file("res://scenes/menu_new.tscn")
