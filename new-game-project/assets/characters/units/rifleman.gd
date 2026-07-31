extends Node2D

@onready var icon: Sprite2D = $Icon
@onready var click_area: Area2D = $ClickArea
@onready var ground: TileMapLayer = get_node("../../Map/Ground")

var is_selected: bool = false
var original_color: Color

var movement_range: int = 4
var reachable_cells: Array[Vector2i] = []


func _ready() -> void:
	original_color = icon.modulate
	click_area.input_event.connect(_on_click_area_input_event)


func _on_click_area_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_selected = not is_selected

			if is_selected:
				icon.modulate = Color(1.0, 1.0, 0.3)
				calculate_reachable_cells()
				print("Rifleman selected")
			else:
				deselect_rifleman()

			queue_redraw()


func calculate_reachable_cells() -> void:
	reachable_cells.clear()

	var current_cell: Vector2i = ground.local_to_map(
		ground.to_local(global_position)
	)

	for x_offset in range(-movement_range, movement_range + 1):
		for y_offset in range(-movement_range, movement_range + 1):

			var distance: int = abs(x_offset) + abs(y_offset)

			if distance == 0:
				continue

			if distance > movement_range:
				continue

			var candidate_cell := current_cell + Vector2i(
				x_offset,
				y_offset
			)

			# Ignore cells without painted ground.
			if ground.get_cell_source_id(candidate_cell) == -1:
				continue

			reachable_cells.append(candidate_cell)


func _unhandled_input(event: InputEvent) -> void:
	if not is_selected:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			try_move_to_mouse_cell()


func try_move_to_mouse_cell() -> void:
	var target_cell: Vector2i = ground.local_to_map(
		ground.get_local_mouse_position()
	)

	if target_cell not in reachable_cells:
		print("That tile is outside movement range.")
		return

	var target_position: Vector2 = ground.map_to_local(target_cell)

	global_position = ground.to_global(target_position)

	print("Rifleman moved to cell: ", target_cell)

	deselect_rifleman()
	queue_redraw()


func deselect_rifleman() -> void:
	is_selected = false
	icon.modulate = original_color
	reachable_cells.clear()

	print("Rifleman deselected")


func _draw() -> void:
	if not is_selected:
		return

	var tile_size := Vector2(ground.tile_set.tile_size)
	var rectangle_size := tile_size - Vector2(2.0, 2.0)

	for cell in reachable_cells:
		var cell_position: Vector2 = ground.map_to_local(cell)
		var global_cell_position: Vector2 = ground.to_global(cell_position)
		var local_cell_position: Vector2 = to_local(global_cell_position)

		var highlight_rectangle := Rect2(
			local_cell_position - rectangle_size / 2.0,
			rectangle_size
		)

		# Transparent blue interior.
		draw_rect(
			highlight_rectangle,
			Color(0.15, 0.55, 1.0, 0.25),
			true
		)

		# Blue border.
		draw_rect(
			highlight_rectangle,
			Color(0.2, 0.7, 1.0, 0.9),
			false,
			1.0
		)
