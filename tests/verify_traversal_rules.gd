extends SceneTree


func _init() -> void:
	_verify_flat_to_flat()
	_verify_invalid_neighbors()
	_verify_cliff_blocked()
	_verify_slope_transitions()
	_verify_occupancy()

	print("Traversal rule verification passed.")
	quit()


func _make_grid(size := Vector2i(4, 4)) -> WorldGrid:
	var grid := WorldGrid.new()
	grid.grid_size = size
	grid.initialize_flat_grid()
	return grid


func _verify_flat_to_flat() -> void:
	var grid := _make_grid()
	assert(grid.can_traverse_between(Vector2i(0, 0), Vector2i(1, 0)))
	assert(grid.get_pathable_neighbors(Vector2i(0, 0)).has(Vector2i(1, 0)))


func _verify_invalid_neighbors() -> void:
	var grid := _make_grid()
	assert(not grid.can_traverse_between(Vector2i(0, 0), Vector2i(-1, 0)))
	assert(not grid.can_traverse_between(Vector2i(0, 0), Vector2i(1, 1)))
	assert(not grid.can_traverse_between(Vector2i(0, 0), Vector2i(2, 0)))


func _verify_cliff_blocked() -> void:
	var grid := _make_grid()
	grid.set_cell_terrain(Vector2i(1, 0), 1, true, true)
	assert(not grid.can_traverse_between(Vector2i(0, 0), Vector2i(1, 0)))


func _verify_slope_transitions() -> void:
	var grid := _make_grid()
	grid.set_cell_terrain(Vector2i(1, 0), 0, true, true, WorldGrid.SLOPE_STRAIGHT, 1, WorldGrid.DIRECTION_EAST)
	grid.set_cell_terrain(Vector2i(2, 0), 1, true, true)

	assert(grid.can_traverse_between(Vector2i(0, 0), Vector2i(1, 0)))
	assert(grid.can_traverse_between(Vector2i(1, 0), Vector2i(2, 0)))
	assert(not grid.can_traverse_between(Vector2i(1, 0), Vector2i(1, 1)))


func _verify_occupancy() -> void:
	var grid := _make_grid()
	grid.set_occupancy(Vector2i(1, 0), true, true)
	assert(not grid.can_traverse_between(Vector2i(0, 0), Vector2i(1, 0)))

	grid.set_occupancy(Vector2i(1, 0), true, false)
	assert(grid.can_traverse_between(Vector2i(0, 0), Vector2i(1, 0)))
	assert(not grid.is_buildable(Vector2i(1, 0)))
