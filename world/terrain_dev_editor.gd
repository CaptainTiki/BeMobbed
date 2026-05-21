extends Node3D
class_name TerrainDevEditor

enum ToolMode {
	NONE,
	HEIGHT,
	FLATTEN,
	SLOPE,
}

@export var world_grid_path: NodePath
@export var dev_mode_manager_path: NodePath
@export var cell_size := 1.0
@export var ray_length := 128.0

var tool_mode := ToolMode.NONE

var _cursor: MeshInstance3D
var _cursor_material: StandardMaterial3D
var _selected_cell := Vector2i(-1, -1)
var _world_grid: WorldGrid
var _dev_mode_manager: Node
var _flatten_drag_height := 0
var _is_flatten_dragging := false
var _painted_flatten_cells: Dictionary = {}


func _ready() -> void:
	_world_grid = get_node_or_null(world_grid_path)
	_dev_mode_manager = get_node_or_null(dev_mode_manager_path)
	_create_cursor()


func _process(_delta: float) -> void:
	if not _is_dev_mode_enabled():
		_cursor.visible = false
		return

	_update_selected_cell()
	_process_active_drag()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_dev_mode_enabled() or _world_grid == null or not _world_grid.is_in_bounds(_selected_cell):
		return

	if tool_mode == ToolMode.SLOPE and event.is_action_pressed("dev_terrain_rotate_slope"):
		_rotate_selected_slope()
		return

	if event.is_action_pressed("dev_terrain_primary"):
		_handle_primary_pressed()
	elif event.is_action_pressed("dev_terrain_secondary"):
		_handle_secondary_pressed()
	elif event.is_action_released("dev_terrain_primary"):
		_is_flatten_dragging = false
		_painted_flatten_cells.clear()

	if event.is_action_pressed("dev_terrain_raise"):
		_world_grid.raise_cell(_selected_cell)
		_update_cursor_position()
	elif event.is_action_pressed("dev_terrain_lower"):
		_world_grid.lower_cell(_selected_cell)
		_update_cursor_position()
	elif event.is_action_pressed("dev_terrain_flatten"):
		_world_grid.flatten_cell(_selected_cell)
		_update_cursor_position()


func set_tool_mode(mode: int) -> void:
	tool_mode = mode
	_is_flatten_dragging = false
	_painted_flatten_cells.clear()
	_update_cursor_visibility()


func _is_dev_mode_enabled() -> bool:
	return _dev_mode_manager == null or _dev_mode_manager.is_dev_mode_enabled()


func get_tool_mode() -> int:
	return tool_mode


func save_current_terrain(path: String) -> bool:
	if _world_grid == null:
		push_warning("Cannot save terrain without a WorldGrid")
		return false

	return _world_grid.save_terrain_file(path)


func _create_cursor() -> void:
	_cursor_material = StandardMaterial3D.new()
	_cursor_material.albedo_color = Color(0.1, 0.9, 1, 0.38)
	_cursor_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cursor_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var mesh := BoxMesh.new()
	mesh.size = Vector3(cell_size * 1.02, 0.05, cell_size * 1.02)

	_cursor = MeshInstance3D.new()
	_cursor.name = "TerrainEditCursor"
	_cursor.mesh = mesh
	_cursor.material_override = _cursor_material
	_cursor.visible = false
	add_child(_cursor)


func _update_selected_cell() -> void:
	if _world_grid == null:
		return

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		_cursor.visible = false
		return

	var ray_start = _get_camera_ray_start(camera)
	if ray_start == null:
		_cursor.visible = false
		return

	var ray_end = _get_camera_ray_end(camera)
	if ray_end == null:
		_cursor.visible = false
		return

	var hit_position = _intersect_ground_plane(ray_start, ray_end)
	if hit_position == null:
		_cursor.visible = false
		return

	var cell := _world_position_to_cell(hit_position)
	if not _world_grid.is_in_bounds(cell):
		_cursor.visible = false
		_selected_cell = Vector2i(-1, -1)
		return

	_selected_cell = cell
	_update_cursor_position()


func _get_camera_ray_start(camera: Camera3D) -> Variant:
	if camera == null:
		return null

	return camera.project_ray_origin(get_viewport().get_mouse_position())


func _get_camera_ray_end(camera: Camera3D) -> Variant:
	if camera == null:
		return null

	var viewport := get_viewport()
	var mouse_position := viewport.get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_direction := camera.project_ray_normal(mouse_position)
	if ray_direction.length_squared() <= 0.0:
		return null

	return ray_origin + ray_direction * ray_length


func _intersect_ground_plane(ray_start: Vector3, ray_end: Vector3) -> Variant:
	var direction := ray_end - ray_start
	if is_zero_approx(direction.y):
		return null

	var t := -ray_start.y / direction.y
	if t < 0.0 or t > 1.0:
		return null

	return ray_start + direction * t


func _handle_primary_pressed() -> void:
	match tool_mode:
		ToolMode.NONE:
			return
		ToolMode.HEIGHT:
			_world_grid.raise_cell(_selected_cell)
			_update_cursor_position()
		ToolMode.FLATTEN:
			_flatten_drag_height = _world_grid.get_height(_selected_cell)
			_is_flatten_dragging = true
			_painted_flatten_cells.clear()
			_flatten_selected_cell()
		ToolMode.SLOPE:
			_apply_slope_to_selected_cell()


func _handle_secondary_pressed() -> void:
	if tool_mode != ToolMode.HEIGHT:
		return

	_world_grid.lower_cell(_selected_cell)
	_update_cursor_position()


func _process_active_drag() -> void:
	if not _is_flatten_dragging:
		return
	if _world_grid == null or not _world_grid.is_in_bounds(_selected_cell):
		return

	_flatten_selected_cell()


func _flatten_selected_cell() -> void:
	if _painted_flatten_cells.has(_selected_cell):
		return

	_world_grid.flatten_cell(_selected_cell, _flatten_drag_height)
	_painted_flatten_cells[_selected_cell] = true
	_update_cursor_position()


func _apply_slope_to_selected_cell() -> void:
	var slope_data := _infer_slope_for_cell(_selected_cell)
	_world_grid.set_cell_terrain(
		_selected_cell,
		slope_data["height"],
		true,
		true,
		slope_data["slope_type"],
		2,
		slope_data["slope_direction"]
	)
	_update_cursor_position()


func _infer_slope_for_cell(cell: Vector2i) -> Dictionary:
	var current_height := _world_grid.get_height(cell)
	var slope_neighbors := _get_slope_neighbor_directions(cell, current_height)
	var raised_neighbors := _get_raised_neighbor_directions(cell, current_height)

	if slope_neighbors.size() == 2:
		if _are_opposite_directions(slope_neighbors[0], slope_neighbors[1]):
			return _make_straight_slope_data(current_height, _get_matching_straight_direction(cell, slope_neighbors))

		if _are_adjacent_directions(slope_neighbors[0], slope_neighbors[1]):
			return _make_corner_slope_data(current_height, _directions_to_corner_direction(slope_neighbors[0], slope_neighbors[1]))

	if slope_neighbors.size() >= 3:
		return _make_flat_slope_fallback(current_height)

	if raised_neighbors.size() == 1:
		return _make_straight_slope_data(current_height, raised_neighbors[0])

	if raised_neighbors.size() > 1:
		return _make_flat_slope_fallback(current_height)

	if slope_neighbors.size() == 1:
		return _make_straight_slope_data(current_height, _get_matching_straight_direction(cell, slope_neighbors))

	return _make_straight_slope_data(current_height, WorldGrid.DIRECTION_NORTH)


func _get_slope_neighbor_directions(cell: Vector2i, current_height: int) -> Array[int]:
	var directions: Array[int] = []
	for direction in _cardinal_directions():
		var neighbor_cell := cell + _direction_to_offset(direction)
		if not _world_grid.is_in_bounds(neighbor_cell):
			continue

		var neighbor_data := _world_grid.get_cell(neighbor_cell)
		if int(neighbor_data.get("height", -1)) != current_height:
			continue

		if TerrainSurface.is_slope(neighbor_data):
			directions.append(direction)

	return directions


func _get_raised_neighbor_directions(cell: Vector2i, current_height: int) -> Array[int]:
	var directions: Array[int] = []
	for direction in _cardinal_directions():
		var neighbor_cell := cell + _direction_to_offset(direction)
		if not _world_grid.is_in_bounds(neighbor_cell):
			continue

		var neighbor_data := _world_grid.get_cell(neighbor_cell)
		if TerrainSurface.is_slope(neighbor_data):
			continue

		if int(neighbor_data.get("height", 0)) > current_height:
			directions.append(direction)

	return directions


func _get_matching_straight_direction(cell: Vector2i, slope_neighbor_directions: Array[int]) -> int:
	for direction in slope_neighbor_directions:
		var neighbor_data := _world_grid.get_cell(cell + _direction_to_offset(direction))
		if neighbor_data.get("slope_type", WorldGrid.SLOPE_FLAT) == WorldGrid.SLOPE_STRAIGHT:
			return int(neighbor_data.get("slope_direction", WorldGrid.DIRECTION_NORTH))

	return slope_neighbor_directions[0]


func _make_straight_slope_data(height: int, direction: int) -> Dictionary:
	return {
		"height": height,
		"slope_type": WorldGrid.SLOPE_STRAIGHT,
		"slope_direction": direction,
	}


func _make_corner_slope_data(height: int, direction: int) -> Dictionary:
	return {
		"height": height,
		"slope_type": WorldGrid.SLOPE_CORNER,
		"slope_direction": direction,
	}


func _make_flat_slope_fallback(height: int) -> Dictionary:
	return {
		"height": height,
		"slope_type": WorldGrid.SLOPE_FLAT,
		"slope_direction": WorldGrid.DIRECTION_NORTH,
	}


func _cardinal_directions() -> Array[int]:
	return [
		WorldGrid.DIRECTION_NORTH,
		WorldGrid.DIRECTION_EAST,
		WorldGrid.DIRECTION_SOUTH,
		WorldGrid.DIRECTION_WEST,
	]


func _are_opposite_directions(first_direction: int, second_direction: int) -> bool:
	return _opposite_direction(first_direction) == second_direction


func _are_adjacent_directions(first_direction: int, second_direction: int) -> bool:
	return not _are_opposite_directions(first_direction, second_direction) and first_direction != second_direction


func _directions_to_corner_direction(first_direction: int, second_direction: int) -> int:
	var directions := [first_direction, second_direction]
	if directions.has(WorldGrid.DIRECTION_NORTH) and directions.has(WorldGrid.DIRECTION_EAST):
		return WorldGrid.DIRECTION_EAST
	if directions.has(WorldGrid.DIRECTION_EAST) and directions.has(WorldGrid.DIRECTION_SOUTH):
		return WorldGrid.DIRECTION_SOUTH
	if directions.has(WorldGrid.DIRECTION_SOUTH) and directions.has(WorldGrid.DIRECTION_WEST):
		return WorldGrid.DIRECTION_WEST
	if directions.has(WorldGrid.DIRECTION_WEST) and directions.has(WorldGrid.DIRECTION_NORTH):
		return WorldGrid.DIRECTION_NORTH

	return first_direction


func _rotate_selected_slope() -> void:
	var data := _world_grid.get_cell(_selected_cell)
	if data.is_empty():
		return

	var slope_type: StringName = data.get("slope_type", WorldGrid.SLOPE_FLAT)
	if not TerrainSurface.is_slope(data):
		slope_type = WorldGrid.SLOPE_STRAIGHT

	_world_grid.set_cell_terrain(
		_selected_cell,
		int(data.get("height", 0)),
		bool(data.get("walkable", true)),
		bool(data.get("buildable", true)),
		slope_type,
		int(data.get("path_cost", 2)),
		(int(data.get("slope_direction", WorldGrid.DIRECTION_NORTH)) + 1) % 4
	)
	_update_cursor_position()


func _direction_to_offset(direction: int) -> Vector2i:
	match direction:
		WorldGrid.DIRECTION_NORTH:
			return Vector2i(0, -1)
		WorldGrid.DIRECTION_EAST:
			return Vector2i(1, 0)
		WorldGrid.DIRECTION_SOUTH:
			return Vector2i(0, 1)
		WorldGrid.DIRECTION_WEST:
			return Vector2i(-1, 0)

	return Vector2i.ZERO


func _opposite_direction(direction: int) -> int:
	return (direction + 2) % 4


func _world_position_to_cell(world_position: Vector3) -> Vector2i:
	var half_size := Vector2(_world_grid.grid_size) * cell_size * 0.5
	return Vector2i(
		floori((world_position.x + half_size.x) / cell_size),
		floori((world_position.z + half_size.y) / cell_size)
	)


func _cell_to_world_position(cell: Vector2i) -> Vector3:
	var half_size := Vector2(_world_grid.grid_size) * cell_size * 0.5
	var data := _world_grid.get_cell(cell)
	var top_heights := TerrainSurface.get_top_corner_heights(data)
	var top_y := 0.0

	for height in top_heights:
		top_y += height
	top_y /= float(top_heights.size())

	return Vector3(
		(float(cell.x) + 0.5) * cell_size - half_size.x,
		top_y + 0.08,
		(float(cell.y) + 0.5) * cell_size - half_size.y
	)


func _update_cursor_position() -> void:
	if _cursor == null or _world_grid == null or not _world_grid.is_in_bounds(_selected_cell):
		return

	_cursor.global_position = _cell_to_world_position(_selected_cell)
	_update_cursor_visibility()


func _update_cursor_visibility() -> void:
	if _cursor == null:
		return

	_cursor.visible = (
		_is_dev_mode_enabled()
		and tool_mode != ToolMode.NONE
		and _world_grid != null
		and _world_grid.is_in_bounds(_selected_cell)
	)
