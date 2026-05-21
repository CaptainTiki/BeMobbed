extends Node3D
class_name BlockPlacementController

@export var world_grid_path: NodePath
@export var placed_blocks_path: NodePath
@export var hotbar_path: NodePath
@export var block_menu_path: NodePath
@export var terrain_editor_path: NodePath
@export var cell_size := 1.0
@export var ray_length := 128.0

var _world_grid: WorldGrid
var _placed_blocks_root: Node3D
var _hotbar: GenericHotbar
var _block_menu: BlockMenu
var _terrain_editor: TerrainDevEditor
var _ghost: BlockGhost
var _selected_block: BlockDefinition
var _selected_cell := Vector2i(-1, -1)
var _placement_valid := false
var _rotation_steps := 0


func _ready() -> void:
	_world_grid = get_node_or_null(world_grid_path)
	_placed_blocks_root = get_node_or_null(placed_blocks_path)
	_hotbar = get_node_or_null(hotbar_path)
	_block_menu = get_node_or_null(block_menu_path)
	_terrain_editor = get_node_or_null(terrain_editor_path)
	_create_ghost()
	_connect_ui()


func _process(_delta: float) -> void:
	if _selected_block == null or _world_grid == null:
		_ghost.hide_preview()
		return

	_update_selected_cell()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_B:
				if _block_menu != null:
					_block_menu.toggle()
					if _block_menu.visible:
						Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
					get_viewport().set_input_as_handled()
			KEY_R:
				if _selected_block != null:
					_rotation_steps = (_rotation_steps + 1) % 4
					_ghost.rotation.y = float(_rotation_steps) * PI * 0.5
					get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				if is_placement_active():
					cancel_placement()
					get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_placement_active():
			_try_place_selected_block()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if is_placement_active():
			cancel_placement()
			get_viewport().set_input_as_handled()


func set_selected_block(definition: BlockDefinition) -> void:
	if definition == null:
		cancel_placement()
		return

	_selected_block = definition
	_selected_cell = Vector2i(-1, -1)
	_placement_valid = false
	_rotation_steps = 0
	_ghost.rotation.y = 0.0
	_ghost.set_definition(definition)
	if _terrain_editor != null:
		_terrain_editor.set_tool_mode(TerrainDevEditor.ToolMode.NONE)


func cancel_placement() -> void:
	_selected_block = null
	_selected_cell = Vector2i(-1, -1)
	_placement_valid = false
	_rotation_steps = 0
	if _ghost != null:
		_ghost.rotation.y = 0.0
		_ghost.set_definition(null)
		_ghost.hide_preview()


func is_placement_active() -> bool:
	return _selected_block != null


func _connect_ui() -> void:
	if _hotbar != null:
		_hotbar.entry_selected.connect(_on_hotbar_entry_selected)
	if _block_menu != null:
		_block_menu.block_selected.connect(_on_block_menu_block_selected)


func _create_ghost() -> void:
	_ghost = BlockGhost.new()
	_ghost.name = "BlockGhost"
	_ghost.cell_size = cell_size
	add_child(_ghost)


func _on_hotbar_entry_selected(_slot_index: int, entry: HotbarEntry) -> void:
	if entry == null or entry.entry_type != HotbarEntry.EntryType.BLOCK:
		cancel_placement()
		return

	set_selected_block(entry.block_definition)


func _on_block_menu_block_selected(definition: BlockDefinition) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_selected_block(definition)


func _update_selected_cell() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		_ghost.hide_preview()
		return

	var mouse_position := get_viewport().get_mouse_position()
	var ray_start := camera.project_ray_origin(mouse_position)
	var ray_end := ray_start + camera.project_ray_normal(mouse_position) * ray_length
	var hit_position = _intersect_ground_plane(ray_start, ray_end)
	if hit_position == null:
		_ghost.hide_preview()
		return

	_selected_cell = _world_position_to_cell(hit_position)
	if not _world_grid.is_in_bounds(_selected_cell):
		_placement_valid = false
		_ghost.hide_preview()
		return

	_placement_valid = _can_place_block(_selected_block, _selected_cell)
	_ghost.update_preview(_cell_to_block_world_position(_selected_cell, _selected_block), _placement_valid)


func _try_place_selected_block() -> bool:
	if _selected_block == null or _world_grid == null or _placed_blocks_root == null:
		return false
	if not _placement_valid:
		return false

	var instance := _selected_block.scene.instantiate() as Node3D
	if instance == null:
		push_warning("Block scene for %s does not instantiate as Node3D" % _selected_block.id)
		return false

	var cells := _get_footprint_cells(_selected_cell, _selected_block.footprint, _rotation_steps)
	instance.global_position = _cell_to_block_world_position(_selected_cell, _selected_block)
	instance.rotation.y = float(_rotation_steps) * PI * 0.5
	if instance.has_method("setup"):
		instance.setup(_selected_block, _selected_cell, cells)

	_placed_blocks_root.add_child(instance)
	for cell in cells:
		_world_grid.set_occupancy(cell, _selected_block.blocks_building, _selected_block.blocks_movement)

	_placement_valid = _can_place_block(_selected_block, _selected_cell)
	return true


func _can_place_block(definition: BlockDefinition, origin_cell: Vector2i) -> bool:
	if definition == null:
		return false

	var cells := _get_footprint_cells(origin_cell, definition.footprint, _rotation_steps)
	var reference_height := 0
	var has_reference_height := false

	for cell in cells:
		if not _world_grid.is_in_bounds(cell) or not _world_grid.is_buildable(cell):
			return false

		var data := _world_grid.get_cell(cell)
		if definition.requires_flat_ground and TerrainSurface.is_slope(data):
			return false

		var height := _get_cell_top_height(cell)
		if not has_reference_height:
			reference_height = height
			has_reference_height = true
		elif definition.requires_flat_ground and height != reference_height:
			return false

	return true


func _get_footprint_cells(origin_cell: Vector2i, footprint: Vector2i, rotation_steps: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var rotated_footprint := _get_rotated_footprint(footprint, rotation_steps)
	for z in range(rotated_footprint.y):
		for x in range(rotated_footprint.x):
			cells.append(origin_cell + Vector2i(x, z))

	return cells


func _get_rotated_footprint(footprint: Vector2i, rotation_steps: int) -> Vector2i:
	if abs(rotation_steps) % 2 == 1:
		return Vector2i(footprint.y, footprint.x)

	return footprint


func _intersect_ground_plane(ray_start: Vector3, ray_end: Vector3) -> Variant:
	var direction := ray_end - ray_start
	if is_zero_approx(direction.y):
		return null

	var t := -ray_start.y / direction.y
	if t < 0.0 or t > 1.0:
		return null

	return ray_start + direction * t


func _world_position_to_cell(world_position: Vector3) -> Vector2i:
	var half_size := Vector2(_world_grid.grid_size) * cell_size * 0.5
	return Vector2i(
		floori((world_position.x + half_size.x) / cell_size),
		floori((world_position.z + half_size.y) / cell_size)
	)


func _cell_to_block_world_position(cell: Vector2i, definition: BlockDefinition) -> Vector3:
	var half_size := Vector2(_world_grid.grid_size) * cell_size * 0.5
	var footprint := Vector2(_get_rotated_footprint(definition.footprint, _rotation_steps))
	var center_offset := (footprint - Vector2.ONE) * cell_size * 0.5

	return Vector3(
		(float(cell.x) + 0.5) * cell_size - half_size.x + center_offset.x,
		float(_get_cell_top_height(cell)),
		(float(cell.y) + 0.5) * cell_size - half_size.y + center_offset.y
	)


func _get_cell_top_height(cell: Vector2i) -> int:
	var data := _world_grid.get_cell(cell)
	var top_heights := TerrainSurface.get_top_corner_heights(data)
	var top_y := 0.0
	for height in top_heights:
		top_y += height

	return roundi(top_y / float(top_heights.size()))
