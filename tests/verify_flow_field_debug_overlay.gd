extends SceneTree


func _init() -> void:
	var level := Node3D.new()
	level.name = "Level"
	root.add_child(level)

	var world_grid := WorldGrid.new()
	world_grid.name = "WorldGrid"
	world_grid.grid_size = Vector2i(3, 3)
	level.add_child(world_grid)
	world_grid.initialize_flat_grid()

	var placed_blocks := Node3D.new()
	placed_blocks.name = "PlacedBlocks"
	level.add_child(placed_blocks)

	var generator := FlowFieldGenerator.new()
	generator.name = "FlowFieldGenerator"
	level.add_child(generator)

	var overlay := FlowFieldDebugOverlay.new()
	overlay.name = "FlowFieldDebugOverlay"
	overlay.world_grid_path = NodePath("../WorldGrid")
	overlay.flow_field_generator_path = NodePath("../FlowFieldGenerator")
	overlay.placed_blocks_path = NodePath("../PlacedBlocks")
	level.add_child(overlay)

	await process_frame

	overlay.refresh_flow_field()
	assert(overlay.current_flow_field == null)
	assert(overlay.get_node("CostCells").get_child_count() == 0)
	overlay.set_overlay_visible(true)
	assert(overlay.visible)
	overlay.set_overlay_visible(false)
	assert(not overlay.visible)

	var definition := BlockDefinition.new()
	definition.id = &"test_core"
	definition.display_name = "Test Core"
	var placed_block := PlacedBlock.new()
	placed_block.name = "TestCore"
	placed_block.setup(definition, Vector2i(1, 1), [Vector2i(1, 1)])
	placed_blocks.add_child(placed_block)
	world_grid.set_occupancy(Vector2i(1, 1), true, true)

	overlay.set_overlay_visible(true)
	assert(overlay.current_flow_field != null)
	assert(overlay.current_flow_field.target_cell == Vector2i(1, 0))
	assert(overlay.get_node("CostCells").get_child_count() > 0)
	assert(overlay.get_node("DirectionArrows") != null)

	level.queue_free()
	print("Flow field debug overlay verification passed.")
	quit()
