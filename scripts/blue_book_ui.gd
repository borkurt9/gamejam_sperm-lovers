extends CanvasLayer

signal answer_correct(table: Node)
signal answer_wrong(table: Node)

enum State {
	HIDDEN,
	SHOWING_COVER,
	SHOWING_QUESTION
}

@onready var overlay: ColorRect = $Overlay
@onready var book_cover: Panel = $BookCover
@onready var book_inside: Panel = $BookInside
@onready var question_label: Label = $BookInside/QuestionLabel
@onready var answer_input: LineEdit = $BookInside/AnswerInput
@onready var submit_button: Button = $BookInside/SubmitButton
@onready var hint_label: Label = $BookCover/HintLabel
@onready var success_sound: AudioStreamPlayer = $SuccessSound
@onready var error_sound: AudioStreamPlayer = $ErrorSound

var current_state: State = State.HIDDEN
var current_table: Node = null


func _ready() -> void:
	add_to_group("blue_book_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Hide everything initially
	overlay.visible = false
	book_cover.visible = false
	book_inside.visible = false

	# Connect signals
	submit_button.pressed.connect(_on_submit)
	answer_input.text_submitted.connect(_on_text_submitted)


func _input(event: InputEvent) -> void:
	if current_state == State.HIDDEN:
		return

	# Flip book open with click or spacebar when showing cover
	if current_state == State.SHOWING_COVER:
		if event.is_action_pressed("shoot") or event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			flip_open()
			return

	# Close book with escape
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_book()


func show_book(table: Node) -> void:
	if current_state != State.HIDDEN:
		return

	current_table = table
	current_state = State.SHOWING_COVER

	# Show overlay and cover
	overlay.visible = true
	book_cover.visible = true
	book_inside.visible = false

	# Pause the game
	get_tree().paused = true


func flip_open() -> void:
	if current_state != State.SHOWING_COVER:
		return

	current_state = State.SHOWING_QUESTION

	# Hide cover, show question panel
	book_cover.visible = false
	book_inside.visible = true

	# Set the question text
	if current_table:
		question_label.text = current_table.problem_text

	# Clear and focus input
	answer_input.text = ""
	answer_input.grab_focus()


func close_book() -> void:
	current_state = State.HIDDEN
	current_table = null

	# Hide everything
	overlay.visible = false
	book_cover.visible = false
	book_inside.visible = false

	# Unpause the game
	get_tree().paused = false


func _on_submit() -> void:
	_validate_answer()


func _on_text_submitted(_text: String) -> void:
	_validate_answer()


func _validate_answer() -> void:
	if not current_table:
		close_book()
		return

	var player_answer = answer_input.text

	if current_table.check_answer(player_answer):
		# Correct answer
		if success_sound:
			success_sound.play()

		# Mark table as complete
		current_table.mark_complete()

		answer_correct.emit(current_table)
		close_book()
	else:
		# Wrong answer
		if error_sound:
			error_sound.play()

		# Damage the player
		_damage_player()

		answer_wrong.emit(current_table)
		close_book()


func _damage_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage"):
		# Damage player with small amount (1-2 HP), no knockback
		player.take_damage(1, player.global_position, false)
