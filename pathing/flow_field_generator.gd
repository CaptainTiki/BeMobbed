extends Node
class_name FlowFieldGenerator

const DIRECTION_CHECK_ORDER: Array[Vector2i] = [
	WorldGrid.OFFSET_NORTH,
	WorldGrid.OFFSET_EAST,
	WorldGrid.OFFSET_SOUTH,
	WorldGrid.OFFSET_WEST,
]


func generate(world_grid: WorldGrid, target_cell: Vector2i) -> FlowField:
	if world_grid == null:
		push_warning("Cannot generate flow field without a WorldGrid")
		return null
	if not world_grid.is_in_bounds(target_cell):
		push_warning("Cannot generate flow field for out-of-bounds target %s" % target_cell)
		return null
	if not world_grid.is_walkable(target_cell):
		push_warning("Cannot generate flow field for unwalkable target %s" % target_cell)
		return null

	var flow_field := FlowField.new()
	flow_field.setup(world_grid.grid_size, target_cell)
	flow_field.set_distance(target_cell, 0.0)

	_generate_distances(world_grid, flow_field, target_cell)
	_generate_directions(world_grid, flow_field)
	return flow_field


func _generate_distances(world_grid: WorldGrid, flow_field: FlowField, target_cell: Vector2i) -> void:
	var open_cells: Array[Vector2i] = [target_cell]

	while not open_cells.is_empty():
		var current_cell := _take_lowest_cost_cell(open_cells, flow_field)
		var current_cost := flow_field.get_distance(current_cell)

		for neighbor in world_grid.get_pathable_neighbors(current_cell):
			var new_cost := current_cost + world_grid.get_path_cost(neighbor)
			if new_cost >= flow_field.get_distance(neighbor):
				continue

			flow_field.set_distance(neighbor, new_cost)
			if not open_cells.has(neighbor):
				open_cells.append(neighbor)


func _generate_directions(world_grid: WorldGrid, flow_field: FlowField) -> void:
	for z in range(flow_field.grid_size.y):
		for x in range(flow_field.grid_size.x):
			var cell := Vector2i(x, z)
			flow_field.set_direction(cell, _get_best_direction(world_grid, flow_field, cell))


func _get_best_direction(world_grid: WorldGrid, flow_field: FlowField, cell: Vector2i) -> Vector2i:
	if not flow_field.is_reachable(cell) or flow_field.is_target(cell):
		return Vector2i.ZERO

	var current_distance := flow_field.get_distance(cell)
	var best_distance := current_distance
	var best_direction := Vector2i.ZERO
	var pathable_neighbors := world_grid.get_pathable_neighbors(cell)

	for direction in DIRECTION_CHECK_ORDER:
		var neighbor := cell + direction
		if not pathable_neighbors.has(neighbor):
			continue

		var neighbor_distance := flow_field.get_distance(neighbor)
		if neighbor_distance < best_distance:
			best_distance = neighbor_distance
			best_direction = direction

	return best_direction


func _take_lowest_cost_cell(open_cells: Array[Vector2i], flow_field: FlowField) -> Vector2i:
	var best_index := 0
	var best_cost := flow_field.get_distance(open_cells[0])

	for index in range(1, open_cells.size()):
		var cost := flow_field.get_distance(open_cells[index])
		if cost < best_cost:
			best_index = index
			best_cost = cost

	return open_cells.pop_at(best_index)
