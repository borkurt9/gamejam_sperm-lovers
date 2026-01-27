extends Node

signal karma_updated(level: int, progress: float, is_positive: bool)

const XP_PER_LEVEL: float = 100.0

var raw_karma: float = 0.0


func add_karma_xp(amount: float) -> void:
	raw_karma += amount / XP_PER_LEVEL
	var level = get_karma_level()
	var progress = get_karma_progress()
	var is_positive = raw_karma >= 0.0
	print("[GameManager] Karma XP: ", amount, " | Raw: ", raw_karma, " | Level: ", level, " | Progress: ", progress)
	karma_updated.emit(level, progress, is_positive)


func get_karma_level() -> int:
	if raw_karma >= 0.0:
		return int(floor(raw_karma))
	else:
		return int(ceil(raw_karma))


func get_karma_progress() -> float:
	var level = get_karma_level()
	return abs(raw_karma - float(level))


func reset_karma() -> void:
	raw_karma = 0.0
	karma_updated.emit(0, 0.0, true)
