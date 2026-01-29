extends Control

## Custom control that draws a radial progress arc
## Gets state from parent ValveProgressBar3D

func _draw() -> void:
	var parent = get_parent().get_parent()  # SubViewport -> Node3D
	if not parent or not parent.has_method("get_draw_progress"):
		return

	var progress = parent.get_draw_progress()
	var fill_color = parent.get_draw_color()
	var bg_color = parent.get_bg_color()
	var arc_width = parent.get_arc_width()

	var center = size / 2
	var radius = min(size.x, size.y) / 2 - arc_width / 2 - 4

	# Draw background circle (full ring)
	draw_arc(center, radius, 0, TAU, 64, bg_color, arc_width)

	# Draw progress arc (clockwise from top)
	if progress > 0.001:
		var start_angle = -PI / 2  # Start at top
		var end_angle = start_angle + (progress * TAU)
		draw_arc(center, radius, start_angle, end_angle, 64, fill_color, arc_width)

	# Draw center circle background
	var inner_radius = radius - arc_width / 2 - 4
	if inner_radius > 0:
		draw_circle(center, inner_radius, Color(0.1, 0.1, 0.1, 0.9))
