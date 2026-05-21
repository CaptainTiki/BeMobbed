extends Node3D

@export var world_grid_path: NodePath
@export var cell_size := 1.0
@export var height_offset := 0.055
@export var visible_on_start := false

var _walkable_material: StandardMaterial3D
var _blocked_material: StandardMaterial3D
var _ramp_material: StandardMaterial3D


func _ready() -> void:
	visible = visible_on_start
	_create_materials()
	call_deferred("rebuild")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_toggle_pathability_overlay"):
		visible = not visible


func rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var world_grid: WorldGrid = get_node_or_null(world_grid_path)
	if world_grid == null:
		push_warning("PathabilityOverlay needs a WorldGrid node")
		return
	if not world_grid.terrain_changed.is_connected(rebuild):
		world_grid.terrain_changed.connect(rebuild)

	var cells := world_grid.get_all_cells()
	var grid_size := world_grid.grid_size
	var half_size := Vector2(grid_size) * cell_size * 0.5
	var walkable_cells: Array[Vector2i] = []
	var ramp_cells: Array[Vector2i] = []
	var blocked_cells: Array[Vector2i] = []

	for cell: Vector2i in cells:
		var data: Dictionary = cells[cell]
		if not world_grid.is_walkable(cell):
			blocked_cells.append(cell)
		elif TerrainSurface.is_slope(data):
			ramp_cells.append(cell)
		else:
			walkable_cells.append(cell)

	_add_overlay_mesh("WalkableCells", walkable_cells, cells, half_size, _walkable_material)
	_add_overlay_mesh("RampCells", ramp_cells, cells, half_size, _ramp_material)
	_add_overlay_mesh("BlockedCells", blocked_cells, cells, half_size, _blocked_material)

	print("PathabilityOverlay rebuilt: %s walkable, %s ramp, %s blocked" % [
		walkable_cells.size(),
		ramp_cells.size(),
		blocked_cells.size(),
	])


func _create_materials() -> void:
	_walkable_material = _make_material(Color(0.1, 0.85, 0.32, 0.28))
	_blocked_material = _make_material(Color(0.95, 0.12, 0.1, 0.48))
	_ramp_material = _make_material(Color(0.95, 0.74, 0.12, 0.44))


func _add_overlay_mesh(
	mesh_name: String,
	overlay_cells: Array[Vector2i],
	all_cells: Dictionary,
	half_size: Vector2,
	material: StandardMaterial3D
) -> void:
	if overlay_cells.is_empty():
		return

	var mesh_instance := MeshInstance3D.new()
	var overlay_mesh := ImmediateMesh.new()
	mesh_instance.name = mesh_name
	mesh_instance.mesh = overlay_mesh

	overlay_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	for cell in overlay_cells:
		_add_cell_quad(overlay_mesh, cell, all_cells[cell], half_size)
	overlay_mesh.surface_end()

	add_child(mesh_instance)


func _add_cell_quad(overlay_mesh: ImmediateMesh, cell: Vector2i, data: Dictionary, half_size: Vector2) -> void:
	var inset := cell_size * 0.04
	var min_x := float(cell.x) * cell_size - half_size.x + inset
	var max_x := min_x + cell_size - inset * 2.0
	var min_z := float(cell.y) * cell_size - half_size.y + inset
	var max_z := min_z + cell_size - inset * 2.0
	var top_heights := TerrainSurface.get_top_corner_heights(data)

	var a := Vector3(min_x, top_heights[0] + height_offset, min_z)
	var b := Vector3(max_x, top_heights[1] + height_offset, min_z)
	var c := Vector3(max_x, top_heights[2] + height_offset, max_z)
	var d := Vector3(min_x, top_heights[3] + height_offset, max_z)

	overlay_mesh.surface_add_vertex(a)
	overlay_mesh.surface_add_vertex(b)
	overlay_mesh.surface_add_vertex(c)
	overlay_mesh.surface_add_vertex(a)
	overlay_mesh.surface_add_vertex(c)
	overlay_mesh.surface_add_vertex(d)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
