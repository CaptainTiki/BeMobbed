extends Node3D
class_name FlowFieldDebugOverlay

const OVERLAY_Y_OFFSET := 0.04
const ARROW_Y_OFFSET := 0.08
const ARROW_LENGTH := 0.32
const ARROW_HEAD_LENGTH := 0.12
const ARROW_HEAD_WIDTH := 0.08
const TARGET_BLOCK_ID: StringName = &"test_core"
const INVALID_TARGET_CELL := Vector2i(-1, -1)
const CORE_SEED_OFFSETS: Array[Vector2i] = [
	WorldGrid.OFFSET_NORTH,
	WorldGrid.OFFSET_EAST,
	WorldGrid.OFFSET_SOUTH,
	WorldGrid.OFFSET_WEST,
]

@export var world_grid_path: NodePath
@export var flow_field_generator_path: NodePath
@export var placed_blocks_path: NodePath
@export var cell_size := 1.0
@export var visible_on_start := false

var current_flow_field: FlowField

var _world_grid: WorldGrid
var _flow_field_generator: FlowFieldGenerator
var _placed_blocks: Node3D
var _cost_cells: Node3D
var _direction_arrows: MeshInstance3D
var _target_material: StandardMaterial3D
var _near_material: StandardMaterial3D
var _mid_material: StandardMaterial3D
var _far_material: StandardMaterial3D
var _unreachable_material: StandardMaterial3D
var _arrow_material: StandardMaterial3D
var _warned_missing_target := false
var _warned_no_pathable_target := false
var _display_target_cell := INVALID_TARGET_CELL


func _ready() -> void:
	_world_grid = get_node_or_null(world_grid_path)
	_flow_field_generator = get_node_or_null(flow_field_generator_path)
	_placed_blocks = get_node_or_null(placed_blocks_path)
	if _flow_field_generator == null:
		_flow_field_generator = FlowFieldGenerator.new()
		_flow_field_generator.name = "InternalFlowFieldGenerator"
		add_child(_flow_field_generator)

	_create_materials()
	_create_containers()
	set_overlay_visible(visible_on_start)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("flow_field_overlay_toggle"):
		toggle_overlay()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("flow_field_refresh"):
		refresh_flow_field()
		get_viewport().set_input_as_handled()


func set_overlay_visible(value: bool) -> void:
	visible = value
	if visible:
		refresh_flow_field()


func toggle_overlay() -> void:
	set_overlay_visible(not visible)


func refresh_flow_field() -> void:
	if _world_grid == null or _flow_field_generator == null:
		clear_overlay()
		return

	var core_cell: Vector2i = _find_test_core_target_cell()
	if core_cell == INVALID_TARGET_CELL:
		if not _warned_missing_target:
			print("FlowFieldDebugOverlay: place a Test Core to generate a debug field.")
			_warned_missing_target = true
		current_flow_field = null
		_display_target_cell = INVALID_TARGET_CELL
		clear_overlay()
		return

	_warned_missing_target = false
	_display_target_cell = core_cell

	var field_target_cell := _get_flow_field_seed_cell(core_cell)
	if field_target_cell == INVALID_TARGET_CELL:
		if not _warned_no_pathable_target:
			print("FlowFieldDebugOverlay: Test Core has no walkable adjacent seed cell.")
			_warned_no_pathable_target = true
		current_flow_field = null
		clear_overlay()
		return

	_warned_no_pathable_target = false
	current_flow_field = _flow_field_generator.generate(_world_grid, field_target_cell)
	if current_flow_field == null:
		clear_overlay()
		return

	print("FlowFieldDebugOverlay: generated field from %s toward Test Core at %s." % [field_target_cell, core_cell])
	_rebuild_overlay()


func clear_overlay() -> void:
	if _cost_cells != null:
		for child in _cost_cells.get_children():
			child.queue_free()
	if _direction_arrows != null:
		_direction_arrows.mesh = null


func _create_containers() -> void:
	_cost_cells = Node3D.new()
	_cost_cells.name = "CostCells"
	add_child(_cost_cells)

	_direction_arrows = MeshInstance3D.new()
	_direction_arrows.name = "DirectionArrows"
	add_child(_direction_arrows)


func _rebuild_overlay() -> void:
	clear_overlay()
	if current_flow_field == null:
		return

	var max_reachable_distance := _get_max_reachable_distance()
	var cells := _world_grid.get_all_cells()
	var grid_size := _world_grid.grid_size
	var half_size := Vector2(grid_size) * cell_size * 0.5
	var arrow_mesh := ImmediateMesh.new()
	arrow_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _arrow_material)

	for cell: Vector2i in cells:
		var data: Dictionary = cells[cell]
		_add_cost_cell(cell, data, half_size, max_reachable_distance)
		_add_direction_arrow(arrow_mesh, cell, data, half_size)

	arrow_mesh.surface_end()
	_direction_arrows.mesh = arrow_mesh


func _add_cost_cell(cell: Vector2i, data: Dictionary, half_size: Vector2, max_reachable_distance: float) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Cell_%s_%s" % [cell.x, cell.y]
	mesh_instance.mesh = _create_cell_mesh(cell, data, half_size, OVERLAY_Y_OFFSET, cell_size * 0.08)
	mesh_instance.material_override = _get_cell_material(cell, max_reachable_distance)
	_cost_cells.add_child(mesh_instance)


func _add_direction_arrow(arrow_mesh: ImmediateMesh, cell: Vector2i, data: Dictionary, half_size: Vector2) -> void:
	if current_flow_field == null or not current_flow_field.is_reachable(cell) or current_flow_field.is_target(cell):
		return

	var direction := current_flow_field.get_direction(cell)
	if direction == Vector2i.ZERO:
		return

	var center := _cell_center_world(cell, data, half_size, ARROW_Y_OFFSET)
	var direction_vector := Vector3(float(direction.x), 0.0, float(direction.y)).normalized()
	var end := center + direction_vector * ARROW_LENGTH
	var side := Vector3(-direction_vector.z, 0.0, direction_vector.x)
	var left_head := end - direction_vector * ARROW_HEAD_LENGTH + side * ARROW_HEAD_WIDTH
	var right_head := end - direction_vector * ARROW_HEAD_LENGTH - side * ARROW_HEAD_WIDTH

	_add_line(arrow_mesh, center, end)
	_add_line(arrow_mesh, end, left_head)
	_add_line(arrow_mesh, end, right_head)


func _create_cell_mesh(cell: Vector2i, data: Dictionary, half_size: Vector2, y_offset: float, inset: float) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var min_x := float(cell.x) * cell_size - half_size.x + inset
	var max_x := min_x + cell_size - inset * 2.0
	var min_z := float(cell.y) * cell_size - half_size.y + inset
	var max_z := min_z + cell_size - inset * 2.0
	var y := _average_cell_height(data) + y_offset

	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.surface_add_vertex(Vector3(min_x, y, min_z))
	mesh.surface_add_vertex(Vector3(max_x, y, min_z))
	mesh.surface_add_vertex(Vector3(max_x, y, max_z))
	mesh.surface_add_vertex(Vector3(min_x, y, min_z))
	mesh.surface_add_vertex(Vector3(max_x, y, max_z))
	mesh.surface_add_vertex(Vector3(min_x, y, max_z))
	mesh.surface_end()
	return mesh


func _cell_center_world(cell: Vector2i, data: Dictionary, half_size: Vector2, y_offset: float) -> Vector3:
	return Vector3(
		(float(cell.x) + 0.5) * cell_size - half_size.x,
		_average_cell_height(data) + y_offset,
		(float(cell.y) + 0.5) * cell_size - half_size.y
	)


func _average_cell_height(data: Dictionary) -> float:
	var top_heights := TerrainSurface.get_top_corner_heights(data)
	var total := 0.0
	for height in top_heights:
		total += height

	return total / float(top_heights.size())


func _get_cell_material(cell: Vector2i, max_reachable_distance: float) -> StandardMaterial3D:
	if current_flow_field.is_target(cell):
		return _target_material
	if cell == _display_target_cell:
		return _target_material
	if not current_flow_field.is_reachable(cell):
		return _unreachable_material

	var distance := current_flow_field.get_distance(cell)
	if max_reachable_distance <= 0.0:
		return _near_material

	var ratio := distance / max_reachable_distance
	if ratio < 0.34:
		return _near_material
	if ratio < 0.67:
		return _mid_material

	return _far_material


func _get_max_reachable_distance() -> float:
	var max_distance := 0.0
	for cell: Vector2i in _world_grid.get_all_cells():
		var distance := current_flow_field.get_distance(cell)
		if distance < FlowField.UNREACHABLE_COST:
			max_distance = max(max_distance, distance)

	return max_distance


func _find_test_core_target_cell() -> Vector2i:
	if _placed_blocks == null:
		return INVALID_TARGET_CELL

	for child in _placed_blocks.get_children():
		var placed_block := child as PlacedBlock
		if placed_block == null:
			continue

		if placed_block.block_id == TARGET_BLOCK_ID:
			return placed_block.anchor_cell
		if placed_block.definition != null and placed_block.definition.id == TARGET_BLOCK_ID:
			return placed_block.grid_cell

	return INVALID_TARGET_CELL


func _get_flow_field_seed_cell(core_cell: Vector2i) -> Vector2i:
	if _world_grid.is_walkable(core_cell):
		return core_cell

	for offset in CORE_SEED_OFFSETS:
		var neighbor := core_cell + offset
		if _world_grid.is_walkable(neighbor):
			return neighbor

	return INVALID_TARGET_CELL


func _add_line(mesh: ImmediateMesh, from: Vector3, to: Vector3) -> void:
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)


func _create_materials() -> void:
	_target_material = _make_material(Color(0.0, 0.85, 1.0, 0.72), 1)
	_near_material = _make_material(Color(0.05, 0.9, 0.32, 0.38), 0)
	_mid_material = _make_material(Color(0.9, 0.82, 0.12, 0.34), 0)
	_far_material = _make_material(Color(1.0, 0.42, 0.08, 0.34), 0)
	_unreachable_material = _make_material(Color(0.48, 0.08, 0.08, 0.42), 0)
	_arrow_material = _make_material(Color(0.0, 0.02, 0.03, 1.0), 10, true)


func _make_material(color: Color, render_priority: int = 0, no_depth_test: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.render_priority = render_priority
	material.no_depth_test = no_depth_test
	return material
