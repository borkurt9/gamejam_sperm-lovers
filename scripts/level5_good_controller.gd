extends Node3D

signal puzzle_completed

@export var exam_table_1: NodePath
@export var exam_table_2: NodePath
@export var exam_table_3: NodePath
@export var exam_table_4: NodePath
@export var exam_table_5: NodePath
@export var door_node: NodePath
@export var blue_book_ui_node: NodePath

@onready var dialog_system: Control = $DialogSystem/ControlNode
@onready var entry_area: Area3D = $EntryArea

var tables: Array[Node] = []
var door: Node = null
var blue_book: Node = null
var completed_count: int = 0
var entry_dialogue_shown: bool = false
var victory_triggered: bool = false


func _ready() -> void:
	# Get table references
	if exam_table_1:
		var table = get_node_or_null(exam_table_1)
		if table:
			tables.append(table)
	if exam_table_2:
		var table = get_node_or_null(exam_table_2)
		if table:
			tables.append(table)
	if exam_table_3:
		var table = get_node_or_null(exam_table_3)
		if table:
			tables.append(table)
	if exam_table_4:
		var table = get_node_or_null(exam_table_4)
		if table:
			tables.append(table)
	if exam_table_5:
		var table = get_node_or_null(exam_table_5)
		if table:
			tables.append(table)

	# Connect table signals
	for table in tables:
		if table.has_signal("table_completed"):
			table.table_completed.connect(_on_table_completed)

	# Get door reference
	if door_node:
		door = get_node_or_null(door_node)

	# Get blue book reference
	if blue_book_ui_node:
		blue_book = get_node_or_null(blue_book_ui_node)

	# Connect entry area for triggering dialogue
	if entry_area:
		entry_area.body_entered.connect(_on_entry_area_body_entered)

	# Stop aggro music, keep default playing
	if GameManager:
		GameManager.aggro_music.stop()

	print("Level5Good controller initialized with ", tables.size(), " tables")


func _on_entry_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not entry_dialogue_shown:
		entry_dialogue_shown = true
		_show_entry_dialogue()


func _show_entry_dialogue() -> void:
	if dialog_system:
		dialog_system.start_dialogue("Level5Good_Entry")


func _on_table_completed(table_id: int) -> void:
	completed_count += 1
	print("Table ", table_id, " completed! Total: ", completed_count, "/5")

	# Award karma for completing a puzzle
	if GameManager:
		GameManager.add_karma_xp(15)

	# Check if all tables are complete
	if completed_count >= 5 and not victory_triggered:
		_trigger_victory()


func _trigger_victory() -> void:
	if victory_triggered:
		return

	victory_triggered = true
	print("All tables completed! Victory!")

	# Award bonus karma
	if GameManager:
		GameManager.add_karma_xp(35)

	# Show victory dialogue
	if dialog_system:
		dialog_system.dialogue_finished.connect(_on_victory_dialogue_finished, CONNECT_ONE_SHOT)
		dialog_system.start_dialogue("Level5Good_Victory")
	else:
		_open_door()


func _on_victory_dialogue_finished() -> void:
	_open_door()


func _open_door() -> void:
	if door and door.has_method("remove_door"):
		door.remove_door()

	# Also emit puzzle_completed signal for any listeners
	puzzle_completed.emit()


func is_completed() -> bool:
	return completed_count >= 5
