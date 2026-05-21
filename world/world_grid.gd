extends Node
class_name WorldGrid

const SLOPE_FLAT : StringName = &"flat"
const SLOPE_RAMP : StringName = &"ramp"

@export var grid_size := Vector2i(64, 64)
@export var default_height := 0
@export var default_path_cost := 1

var _cells: Dictionary = {}


func _ready() -> void:
	initialize_test_arena()


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
				"occupied": false,
				"path_cost": default_path_cost,
			}

	print("WorldGrid initialized: %sx%s cells (%s total)" % [grid_size.x, grid_size.y, _cells.size()])


func initialize_test_arena() -> void:
	initialize_flat_grid()

	for z in range(18, 38):
		for x in range(38, 50):
			set_cell_terrain(Vector2i(x, z), 2, true, true, SLOPE_FLAT, 1)

	for z in range(24, 32):
		for x in range(35, 38):
			set_cell_terrain(Vector2i(x, z), 1, true, true, SLOPE_RAMP, 2)

	for x in range(16, 50):
		if x < 30 or x > 34:
			set_cell_terrain(Vector2i(x, 42), 0, false, false, SLOPE_FLAT, default_path_cost)

	for z in range(20, 38):
		set_cell_terrain(Vector2i(51, z), 3, false, false, SLOPE_FLAT, default_path_cost)

	for z in range(46, 55):
		for x in range(27, 38):
			set_cell_terrain(Vector2i(x, z), 1, true, true, SLOPE_FLAT, 1)

	print("WorldGrid test arena seeded")


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


func get_cell(cell: Vector2i) -> Dictionary:
	if not is_in_bounds(cell):
		return {}

	return _cells.get(cell, {})


func get_all_cells() -> Dictionary:
	return _cells


func get_height(cell: Vector2i) -> int:
	return get_cell(cell).get("height", 0)


func is_walkable(cell: Vector2i) -> bool:
	var data := get_cell(cell)
	return not data.is_empty() and data.get("walkable", false) and not data.get("occupied", false)


func is_buildable(cell: Vector2i) -> bool:
	var data := get_cell(cell)
	return not data.is_empty() and data.get("buildable", false) and not data.get("occupied", false)


func set_occupied(cell: Vector2i, value: bool) -> void:
	if not is_in_bounds(cell):
		push_warning("Tried to set occupancy out of bounds at %s" % cell)
		return

	_cells[cell]["occupied"] = value


func set_cell_terrain(
	cell: Vector2i,
	height: int,
	walkable: bool,
	buildable: bool,
	slope_type: StringName = SLOPE_FLAT,
	path_cost: int = -1
) -> void:
	if not is_in_bounds(cell):
		push_warning("Tried to set terrain out of bounds at %s" % cell)
		return

	_cells[cell]["height"] = height
	_cells[cell]["walkable"] = walkable
	_cells[cell]["buildable"] = buildable
	_cells[cell]["slope_type"] = slope_type
	_cells[cell]["path_cost"] = default_path_cost if path_cost < 0 else path_cost


func get_path_cost(cell: Vector2i) -> int:
	return get_cell(cell).get("path_cost", default_path_cost)
