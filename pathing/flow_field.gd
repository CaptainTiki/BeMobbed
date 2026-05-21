extends RefCounted
class_name FlowField

const UNREACHABLE_COST := 999999999.0

var grid_size := Vector2i.ZERO
var target_cell := Vector2i(-1, -1)

var _distances: Dictionary = {}
var _directions: Dictionary = {}


func setup(size: Vector2i, target: Vector2i) -> void:
	grid_size = size
	target_cell = target
	_distances.clear()
	_directions.clear()

	for z in range(grid_size.y):
		for x in range(grid_size.x):
			var cell := Vector2i(x, z)
			_distances[cell] = UNREACHABLE_COST
			_directions[cell] = Vector2i.ZERO


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


func get_distance(cell: Vector2i) -> float:
	if not is_in_bounds(cell):
		return UNREACHABLE_COST

	return float(_distances.get(cell, UNREACHABLE_COST))


func set_distance(cell: Vector2i, value: float) -> void:
	if not is_in_bounds(cell):
		return

	_distances[cell] = value


func get_direction(cell: Vector2i) -> Vector2i:
	if not is_in_bounds(cell):
		return Vector2i.ZERO

	return _directions.get(cell, Vector2i.ZERO)


func set_direction(cell: Vector2i, direction: Vector2i) -> void:
	if not is_in_bounds(cell):
		return

	_directions[cell] = direction


func is_reachable(cell: Vector2i) -> bool:
	return get_distance(cell) < UNREACHABLE_COST


func is_target(cell: Vector2i) -> bool:
	return cell == target_cell
