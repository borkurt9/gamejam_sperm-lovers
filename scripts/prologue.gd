extends Control

signal prologue_finished

@export var text_speed: float = 30.0

@onready var chapter_label: RichTextLabel = $CanvasLayer/VBoxContainer/ChapterLabel
@onready var text_label: RichTextLabel = $CanvasLayer/VBoxContainer/Panel/TextLabel
@onready var page_indicator: Label = $CanvasLayer/VBoxContainer/PageIndicator
@onready var hint_label: Label = $CanvasLayer/HintLabel
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var pages: Array[Dictionary] = [
	{
		"chapter": "CHAPTER 0: THE RACE",
		"text": "You are one of 300 million.\n\nMost will perish in the first minute.\nThe rest will tire and fall behind.\nOnly ONE can reach the egg."
	},
	{
		"chapter": "CHAPTER 0.1: THE ANOMALY",
		"text": "But you... you're different.\n\nYou woke up.\nYou can THINK.\nAnd somehow... you have a SHOTGUN."
	},
	{
		"chapter": "CHAPTER 0.2: THE PATH",
		"text": "There are two ways to the egg:\n\nTHE PACIFIST - Solve puzzles. Help the doors.\nSpare your siblings. Earn KARMA.\n\nTHE VIOLENT - Blast through everything.\nShotgun goes BOOM. Karma goes DOWN.\n\nYour choices matter. Probably."
	},
	{
		"chapter": "SURVIVAL MANUAL",
		"text": "WASD .............. SWIM\nHOLD RIGHT CLICK .. AIM\nLEFT CLICK ........ SHOOT / TALK / INTERACT\n\nTIP: Some doors just want to chat.\nOthers need convincing."
	},
	{
		"chapter": "DISCLAIMER",
		"text": "Doorethy is watching.\nShe's always watching.\n\nGood luck, little one.\n\n[ CLICK TO BEGIN ]"
	}
]

var current_page: int = 0
var is_typing: bool = false
var hint_tween: Tween

func _ready() -> void:
	# Start hint label pulsing animation
	_start_hint_pulse()

	# Show first page
	show_page(current_page)

func _start_hint_pulse() -> void:
	if hint_tween:
		hint_tween.kill()
	hint_tween = create_tween()
	hint_tween.set_loops()
	hint_tween.tween_property(hint_label, "modulate:a", 0.3, 1.0)
	hint_tween.tween_property(hint_label, "modulate:a", 1.0, 1.0)

func show_page(index: int) -> void:
	if index >= pages.size():
		_finish_prologue()
		return

	var page = pages[index]
	chapter_label.text = "[center]" + page["chapter"] + "[/center]"
	text_label.text = "[center]" + page["text"] + "[/center]"
	text_label.visible_characters = 0
	page_indicator.text = "Page %d / %d" % [index + 1, pages.size()]

	is_typing = true
	set_process(true)

	# Trigger glitch effect on Page 2 (index 1)
	if index == 1:
		await get_tree().create_timer(0.5).timeout
		_trigger_glitch()

func _process(delta: float) -> void:
	if not is_typing:
		set_process(false)
		return

	var total = text_label.get_total_character_count()
	if text_label.visible_characters >= total:
		is_typing = false
		set_process(false)
		return

	text_label.visible_characters += int(delta * text_speed) + 1
	text_label.visible_characters = mini(text_label.visible_characters, total)

func _unhandled_input(event: InputEvent) -> void:
	var advance = false

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			advance = true
	elif event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed:
			advance = true

	if advance:
		get_viewport().set_input_as_handled()

		# If still typing, complete the text instantly
		if is_typing:
			text_label.visible_characters = text_label.get_total_character_count()
			is_typing = false
			return

		# Otherwise, go to next page
		current_page += 1
		show_page(current_page)

func _trigger_glitch() -> void:
	# Screen shake effect via tween
	var original_pos = canvas_layer.offset
	var shake_tween = create_tween()
	shake_tween.tween_property(canvas_layer, "offset", original_pos + Vector2(5, -3), 0.05)
	shake_tween.tween_property(canvas_layer, "offset", original_pos + Vector2(-4, 4), 0.05)
	shake_tween.tween_property(canvas_layer, "offset", original_pos + Vector2(3, -2), 0.05)
	shake_tween.tween_property(canvas_layer, "offset", original_pos + Vector2(-5, 3), 0.05)
	shake_tween.tween_property(canvas_layer, "offset", original_pos + Vector2(2, -4), 0.05)
	shake_tween.tween_property(canvas_layer, "offset", original_pos, 0.05)

func _finish_prologue() -> void:
	prologue_finished.emit()
	get_tree().change_scene_to_file("res://scenes/levels/Level0.tscn")
