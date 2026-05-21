extends Node
class_name WorldGrid

signal terrain_changed

const SLOPE_FLAT : StringName = &"flat"
const SLOPE_STRAIGHT : StringName = &"straight_slope"
const SLOPE_CORNER : StringName = &"corner_slope"
const SLOPE_RAMP : StringName = SLOPE_STRAIGHT

const DIRECTION_NORTH := 0
const DIRECTION_EAST := 1
const DIRECTION_SOUTH := 2
const DIRECTION_WEST := 3
const EDGE_HEIGHT_EPSILON := 0.01
const OFFSET_NORTH := Vector2i(0, -1)
const OFFSET_EAST := Vector2i(1, 0)
const OFFSET_SOUTH := Vector2i(0, 1)
const OFFSET_WEST := Vector2i(-1, 0)

@export var grid_size := Vector2i(64, 64)
@export var default_height := 0
@export var default_path_cost := 1

var _cells: Dictionary = {}


func _ready() -> void:
	pass


func initialize_flat_grid() -> void:
	_cells.clear()

	for z in range(grid_size.y):
		for x in range(grid_size.x):
			var cell := Vector2i(x, z)
			_cells[cell] = {
				"cell_x": x,
				"cell_z": z,
				"height": default_height,
				"walkable": true,
				"buildable": true,
				"slope_type": SLOPE_FLAT,
				"slope_direction": DIRECTION_NORTH,
				"build_occupied": false,
				"movement_occupied": false,
				"path_cost": default_path_cost,
			}

	print("WorldGrid initialized: %sx%s cells (%s total)" % [grid_size.x, grid_size.y, _cells.size()])


func initialize_test_arena() -> void:
	initialize_flat_grid()

	for z in range(18, 38):
		for x in range(38, 50):
			set_cell_terrain(Vector2i(x, z), 2, true, true, SLOPE_FLAT, 1)

	for z in range(24, 32):
		set_cell_terrain(Vector2i(36, z), 0, true, true, SLOPE_STRAIGHT, 2, DIRECTION_EAST)
		set_cell_terrain(Vector2i(37, z), 1, true, true, SLOPE_STRAIGHT, 2, DIRECTION_EAST)

	for offset in range(4):
		set_cell_terrain(Vector2i(36 + offset, 34 + offset), 0, true, true, SLOPE_CORNER, 2, DIRECTION_NORTH)

	for x in range(16, 50):
		if x < 30 or x > 34:
			set_cell_terrain(Vector2i(x, 42), 0, false, false, SLOPE_FLAT, default_path_cost)

	for z in range(20, 38):
		set_cell_terrain(Vector2i(51, z), 3, false, false, SLOPE_FLAT, default_path_cost)

	for z in range(46, 55):
		for x in range(27, 38):
			set_cell_terrain(Vector2i(x, z), 1, true, true, SLOPE_FLAT, 1)

	print("WorldGrid test arena seeded")
	terrain_changed.emit()


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


func get_cell(cell: Vector2i) -> Dictionary:
	if not is_in_bounds(cell):
		return {}

	return _cells.get(cell, {})


func get_all_cells() -> Dictionary:
	return _cells


func has_cells() -> bool:
	return not _cells.is_empty()


func get_height(cell: Vector2i) -> int:
	return get_cell(cell).get("height", 0)


func is_walkable(cell: Vector2i) -> bool:
	var data := get_cell(cell)
	return not data.is_empty() and data.get("walkable", false) and not data.get("movement_occupied", false)


func is_buildable(cell: Vector2i) -> bool:
	var data := get_cell(cell)
	return not data.is_empty() and data.get("buildable", false) and not data.get("build_occupied", false)


func can_traverse_between(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	if not is_in_bounds(from_cell) or not is_in_bounds(to_cell):
		return false
	if not is_walkable(from_cell) or not is_walkable(to_cell):
		return false

	var delta := to_cell - from_cell
	if abs(delta.x) + abs(delta.y) != 1:
		return false

	var direction := _offset_to_direction(delta)
	if direction < 0:
		return false

	var from_data := get_cell(from_cell)
	var to_data := get_cell(to_cell)
	return TerrainSurface.get_shared_edge_height_delta(from_data, to_data, direction) <= EDGE_HEIGHT_EPSILON


func get_pathable_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for offset in _cardinal_offsets():
		var neighbor := cell + offset
		if can_traverse_between(cell, neighbor):
			neighbors.append(neighbor)

	return neighbors


func set_build_occupied(cell: Vector2i, value: bool) -> void:
	if not is_in_bounds(cell):
		push_warning("Tried to set build occupancy out of bounds at %s" % cell)
		return

	_cells[cell]["build_occupied"] = value
	terrain_changed.emit()


func set_movement_occupied(cell: Vector2i, value: bool) -> void:
	if not is_in_bounds(cell):
		push_warning("Tried to set movement occupancy out of bounds at %s" % cell)
		return

	_cells[cell]["movement_occupied"] = value
	terrain_changed.emit()


func set_occupancy(cell: Vector2i, build_value: bool, movement_value: bool) -> void:
	if not is_in_bounds(cell):
		push_warning("Tried to set occupancy out of bounds at %s" % cell)
		return

	_cells[cell]["build_occupied"] = build_value
	_cells[cell]["movement_occupied"] = movement_value
	terrain_changed.emit()


func set_occupied(cell: Vector2i, value: bool) -> void:
	set_occupancy(cell, value, value)


func set_cell_terrain(
	cell: Vector2i,
	height: int,
	walkable: bool,
	buildable: bool,
	slope_type: StringName = SLOPE_FLAT,
	path_cost: int = -1,
	slope_direction: int = DIRECTION_NORTH
) -> void:
	if not is_in_bounds(cell):
		push_warning("Tried to set terrain out of bounds at %s" % cell)
		return

	_cells[cell]["height"] = height
	_cells[cell]["walkable"] = walkable
	_cells[cell]["buildable"] = buildable
	_cells[cell]["slope_type"] = slope_type
	_cells[cell]["slope_direction"] = slope_direction
	_cells[cell]["path_cost"] = default_path_cost if path_cost < 0 else path_cost
	terrain_changed.emit()


func get_path_cost(cell: Vector2i) -> float:
	return float(get_cell(cell).get("path_cost", default_path_cost))


func raise_cell(cell: Vector2i, amount: int = 1) -> void:
	if not is_in_bounds(cell):
		return

	var data := get_cell(cell)
	set_cell_terrain(
		cell,
		int(data.get("height", 0)) + amount,
		bool(data.get("walkable", true)),
		bool(data.get("buildable", true)),
		WorldGrid.SLOPE_FLAT,
		int(data.get("path_cost", default_path_cost)),
		WorldGrid.DIRECTION_NORTH
	)


func lower_cell(cell: Vector2i, amount: int = 1) -> void:
	if not is_in_bounds(cell):
		return

	var data := get_cell(cell)
	set_cell_terrain(
		cell,
		max(0, int(data.get("height", 0)) - amount),
		bool(data.get("walkable", true)),
		bool(data.get("buildable", true)),
		WorldGrid.SLOPE_FLAT,
		int(data.get("path_cost", default_path_cost)),
		WorldGrid.DIRECTION_NORTH
	)


func flatten_cell(cell: Vector2i, height: int = default_height) -> void:
	if not is_in_bounds(cell):
		return

	var data := get_cell(cell)
	set_cell_terrain(
		cell,
		height,
		bool(data.get("walkable", true)),
		bool(data.get("buildable", true)),
		WorldGrid.SLOPE_FLAT,
		int(data.get("path_cost", default_path_cost)),
		WorldGrid.DIRECTION_NORTH
	)


func save_terrain_file(path: String) -> bool:
	var normalized_path := _normalize_terrain_path(path)
	_ensure_parent_directory(normalized_path)

	var file := FileAccess.open(normalized_path, FileAccess.WRITE)
	if file == null:
		push_warning("Failed to save terrain file '%s': %s" % [normalized_path, error_string(FileAccess.get_open_error())])
		return false

	file.store_string(JSON.stringify(to_terrain_data(), "\t"))
	print("Saved terrain file: %s" % normalized_path)
	return true


func load_terrain_file(path: String) -> bool:
	var normalized_path := _normalize_terrain_path(path)
	if not FileAccess.file_exists(normalized_path):
		push_warning("Terrain file does not exist: %s" % normalized_path)
		return false

	var file := FileAccess.open(normalized_path, FileAccess.READ)
	if file == null:
		push_warning("Failed to load terrain file '%s': %s" % [normalized_path, error_string(FileAccess.get_open_error())])
		return false

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Terrain file is not a valid terrain dictionary: %s" % normalized_path)
		return false

	load_terrain_data(parsed)
	print("Loaded terrain file: %s" % normalized_path)
	return true


func to_terrain_data() -> Dictionary:
	var cells := []
	for cell: Vector2i in _cells:
		var data: Dictionary = _cells[cell]
		cells.append({
			"cell_x": cell.x,
			"cell_z": cell.y,
			"height": int(data.get("height", default_height)),
			"walkable": bool(data.get("walkable", true)),
			"buildable": bool(data.get("buildable", true)),
			"slope_type": String(data.get("slope_type", SLOPE_FLAT)),
			"slope_direction": int(data.get("slope_direction", DIRECTION_NORTH)),
			"build_occupied": bool(data.get("build_occupied", false)),
			"movement_occupied": bool(data.get("movement_occupied", false)),
			"path_cost": int(data.get("path_cost", default_path_cost)),
		})

	return {
		"version": 1,
		"grid_size": {
			"x": grid_size.x,
			"z": grid_size.y,
		},
		"default_height": default_height,
		"default_path_cost": default_path_cost,
		"cells": cells,
	}


func load_terrain_data(data: Dictionary) -> void:
	var size_data: Dictionary = data.get("grid_size", {})
	grid_size = Vector2i(
		int(size_data.get("x", grid_size.x)),
		int(size_data.get("z", grid_size.y))
	)
	default_height = int(data.get("default_height", default_height))
	default_path_cost = int(data.get("default_path_cost", default_path_cost))
	initialize_flat_grid()

	for raw_cell in data.get("cells", []):
		if typeof(raw_cell) != TYPE_DICTIONARY:
			continue

		var cell := Vector2i(int(raw_cell.get("cell_x", 0)), int(raw_cell.get("cell_z", 0)))
		if not is_in_bounds(cell):
			continue

		var legacy_occupied := bool(raw_cell.get("occupied", false))

		_cells[cell] = {
			"cell_x": cell.x,
			"cell_z": cell.y,
			"height": int(raw_cell.get("height", default_height)),
			"walkable": bool(raw_cell.get("walkable", true)),
			"buildable": bool(raw_cell.get("buildable", true)),
			"slope_type": StringName(raw_cell.get("slope_type", String(SLOPE_FLAT))),
			"slope_direction": int(raw_cell.get("slope_direction", DIRECTION_NORTH)),
			"build_occupied": bool(raw_cell.get("build_occupied", legacy_occupied)),
			"movement_occupied": bool(raw_cell.get("movement_occupied", legacy_occupied)),
			"path_cost": int(raw_cell.get("path_cost", default_path_cost)),
		}

	terrain_changed.emit()


func _normalize_terrain_path(path: String) -> String:
	if path.get_extension() == "":
		path += ".json"
	if path.begins_with("res://") or path.begins_with("user://"):
		return path

	return "res://world/terrain/%s" % path


func _ensure_parent_directory(path: String) -> void:
	var base_dir := path.get_base_dir()
	if base_dir == "":
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base_dir))


func _cardinal_offsets() -> Array[Vector2i]:
	return [
		OFFSET_NORTH,
		OFFSET_EAST,
		OFFSET_SOUTH,
		OFFSET_WEST,
	]


func _offset_to_direction(offset: Vector2i) -> int:
	match offset:
		OFFSET_NORTH:
			return DIRECTION_NORTH
		OFFSET_EAST:
			return DIRECTION_EAST
		OFFSET_SOUTH:
			return DIRECTION_SOUTH
		OFFSET_WEST:
			return DIRECTION_WEST

	return -1
