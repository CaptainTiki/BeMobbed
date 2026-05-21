extends SceneTree


func _init() -> void:
	_verify_open_flat_grid()
	_verify_movement_occupancy_routes_around()
	_verify_cliff_blocks_propagation()
	_verify_valid_slope_allows_propagation()
	_verify_build_only_occupancy_allows_propagation()
	_verify_unreachable_island()

	print("Flow field foundation verification passed.")
	quit()


func _make_grid(size := Vector2i(5, 5)) -> WorldGrid:
	var grid := WorldGrid.new()
	grid.grid_size = size
	grid.initialize_flat_grid()
	return grid


func _generate(grid: WorldGrid, target_cell: Vector2i) -> FlowField:
	var generator := FlowFieldGenerator.new()
	var flow_field := generator.generate(grid, target_cell)
	assert(flow_field != null)
	return flow_field


func _verify_open_flat_grid() -> void:
	var grid := _make_grid()
	var target := Vector2i(2, 2)
	var flow_field := _generate(grid, target)

	assert(flow_field.get_distance(target) == 0.0)
	assert(flow_field.get_direction(target) == Vector2i.ZERO)
	assert(flow_field.get_distance(Vector2i(3, 2)) > 0.0)
	assert(flow_field.get_direction(Vector2i(3, 2)) == Vector2i.LEFT)
	assert(flow_field.get_direction(Vector2i(2, 1)) == Vector2i.DOWN)


func _verify_movement_occupancy_routes_around() -> void:
	var grid := _make_grid()
	grid.set_movement_occupied(Vector2i(2, 1), true)

	var flow_field := _generate(grid, Vector2i(2, 2))
	assert(not flow_field.is_reachable(Vector2i(2, 1)))
	assert(flow_field.get_direction(Vector2i(2, 0)) == Vector2i.RIGHT)
	assert(flow_field.is_reachable(Vector2i(2, 0)))


func _verify_cliff_blocks_propagation() -> void:
	var grid := _make_grid(Vector2i(3, 1))
	grid.set_cell_terrain(Vector2i(1, 0), 1, true, true)
	grid.set_cell_terrain(Vector2i(2, 0), 1, true, true)

	var flow_field := _generate(grid, Vector2i(0, 0))
	assert(not flow_field.is_reachable(Vector2i(1, 0)))
	assert(flow_field.get_distance(Vector2i(1, 0)) == FlowField.UNREACHABLE_COST)
	assert(flow_field.get_direction(Vector2i(1, 0)) == Vector2i.ZERO)


func _verify_valid_slope_allows_propagation() -> void:
	var grid := _make_grid(Vector2i(3, 1))
	grid.set_cell_terrain(Vector2i(1, 0), 0, true, true, WorldGrid.SLOPE_STRAIGHT, 1, WorldGrid.DIRECTION_EAST)
	grid.set_cell_terrain(Vector2i(2, 0), 1, true, true)

	var flow_field := _generate(grid, Vector2i(0, 0))
	assert(flow_field.is_reachable(Vector2i(1, 0)))
	assert(flow_field.is_reachable(Vector2i(2, 0)))
	assert(flow_field.get_direction(Vector2i(2, 0)) == Vector2i.LEFT)


func _verify_build_only_occupancy_allows_propagation() -> void:
	var grid := _make_grid(Vector2i(3, 1))
	grid.set_occupancy(Vector2i(1, 0), true, false)

	var flow_field := _generate(grid, Vector2i(0, 0))
	assert(flow_field.is_reachable(Vector2i(1, 0)))
	assert(flow_field.get_direction(Vector2i(1, 0)) == Vector2i.LEFT)


func _verify_unreachable_island() -> void:
	var grid := _make_grid(Vector2i(4, 2))
	for z in range(2):
		grid.set_movement_occupied(Vector2i(1, z), true)

	var flow_field := _generate(grid, Vector2i(0, 0))
	assert(flow_field.is_reachable(Vector2i(0, 1)))
	assert(not flow_field.is_reachable(Vector2i(3, 0)))
	assert(flow_field.get_distance(Vector2i(3, 0)) == FlowField.UNREACHABLE_COST)
	assert(flow_field.get_direction(Vector2i(3, 0)) == Vector2i.ZERO)
