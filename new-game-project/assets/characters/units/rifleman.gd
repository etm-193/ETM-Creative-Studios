extends Node2D

@onready var icon: Sprite2D = $Icon
@onready var click_area: Area2D = $ClickArea

var ground: TileMapLayer
var movement_blockers: TileMapLayer

var is_selected: bool = false
var original_color: Color

var movement_range: int = 4
var reachable_cells: Array[Vector2i] = []


func _ready() -> void:
	var current_scene: Node = get_tree().current_scene

	ground = current_scene.get_node_or_null(
		"Map/Ground"
	) as TileMapLayer

	movement_blockers = current_scene.get_node_or_null(
		"Map/MovementBlockers"
	) as TileMapLayer

	if ground == null:
		push_error(
			"Ground was not found. Make sure Map/Ground exists."
		)
		return

	if movement_blockers == null:
		push_error(
			"MovementBlockers was not found. Make sure Map/MovementBlockers exists."
		)
		return

	original_color = icon.modulate
	click_area.input_event.connect(
		_on_click_area_input_event
	)

	print("Rifleman connected to the map successfully.")


func _on_click_area_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if event is not InputEventMouseButton:
		return

	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if not event.pressed:
		return

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

	var starting_cell: Vector2i = ground.local_to_map(
		ground.to_local(global_position)
	)

	var frontier: Array[Vector2i] = [starting_cell]

	var distance_from_start: Dictionary = {
		starting_cell: 0
	}

	var directions: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]

	while not frontier.is_empty():
		var current_cell: Vector2i = frontier.pop_front()

		var current_distance: int = int(
			distance_from_start[current_cell]
		)

		if current_distance >= movement_range:
			continue

		for direction: Vector2i in directions:
			var next_cell: Vector2i = (
				current_cell + direction
			)

			if distance_from_start.has(next_cell):
				continue

			if not is_cell_walkable(next_cell):
				continue

			distance_from_start[next_cell] = (
				current_distance + 1
			)

			frontier.push_back(next_cell)
			reachable_cells.append(next_cell)


func is_cell_walkable(cell: Vector2i) -> bool:
	if ground == null:
		return false

	if movement_blockers == null:
		return false

	# The cell must contain a painted Ground tile.
	if ground.get_cell_source_id(cell) == -1:
		return false

	# Any painted tile on MovementBlockers forbids movement.
	if movement_blockers.get_cell_source_id(cell) != -1:
		return false

	return true


func _unhandled_input(event: InputEvent) -> void:
	if not is_selected:
		return

	if event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_RIGHT
			and event.pressed
		):
			try_move_to_mouse_cell()


func try_move_to_mouse_cell() -> void:
	var target_cell: Vector2i = ground.local_to_map(
		ground.get_local_mouse_position()
	)

	if target_cell not in reachable_cells:
		print("That tile cannot be reached.")
		return

	var target_position: Vector2 = ground.map_to_local(
		target_cell
	)

	global_position = ground.to_global(target_position)

	print("Rifleman moved to cell: ", target_cell)

	deselect_rifleman()


func deselect_rifleman() -> void:
	is_selected = false
	icon.modulate = original_color
	reachable_cells.clear()

	queue_redraw()

	print("Rifleman deselected")


func _draw() -> void:
	if not is_selected:
		return

	if ground == null:
		return

	var tile_size := Vector2(
		ground.tile_set.tile_size
	)

	var rectangle_size := tile_size - Vector2(2.0, 2.0)

	for cell: Vector2i in reachable_cells:
		var cell_position: Vector2 = ground.map_to_local(
			cell
		)

		var global_cell_position: Vector2 = ground.to_global(
			cell_position
		)

		var local_cell_position: Vector2 = to_local(
			global_cell_position
		)

		var highlight_rectangle := Rect2(
			local_cell_position - rectangle_size / 2.0,
			rectangle_size
		)

		draw_rect(
			highlight_rectangle,
			Color(0.15, 0.55, 1.0, 0.25),
			true
		)

		draw_rect(
			highlight_rectangle,
			Color(0.2, 0.7, 1.0, 0.9),
			false,
			1.0
		)
