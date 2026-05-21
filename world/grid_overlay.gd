extends MeshInstance3D

@export var world_grid_path: NodePath
@export var cell_size := 1.0
@export var height_offset := 0.035
@export var visible_on_start := true

var _material: StandardMaterial3D


func _ready() -> void:
	visible = visible_on_start
	_create_material()
	call_deferred("rebuild")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_toggle_grid_overlay"):
		visible = not visible


func rebuild() -> void:
	var world_grid := get_node_or_null(world_grid_path)
	if world_grid == null:
		push_warning("GridOverlay needs a WorldGrid node")
		return

	var cells: Dictionary = world_grid.get_all_cells()
	var grid_size: Vector2i = world_grid.grid_size
	var half_size := Vector2(grid_size) * cell_size * 0.5
	var overlay_mesh := ImmediateMesh.new()

	overlay_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _material)
	for cell: Vector2i in cells:
		var data: Dictionary = cells[cell]
		_add_cell_outline(overlay_mesh, cell, data, half_size)
	overlay_mesh.surface_end()

	mesh = overlay_mesh


func _create_material() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.08, 0.12, 0.14, 0.72)
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func _add_cell_outline(overlay_mesh: ImmediateMesh, cell: Vector2i, data: Dictionary, half_size: Vector2) -> void:
	var height := float(data.get("height", 0))
	var min_x := float(cell.x) * cell_size - half_size.x
	var max_x := min_x + cell_size
	var min_z := float(cell.y) * cell_size - half_size.y
	var max_z := min_z + cell_size
	var y := height + height_offset

	var a := Vector3(min_x, y, min_z)
	var b := Vector3(max_x, y, min_z)
	var c := Vector3(max_x, y, max_z)
	var d := Vector3(min_x, y, max_z)

	_add_line(overlay_mesh, a, b)
	_add_line(overlay_mesh, b, c)
	_add_line(overlay_mesh, c, d)
	_add_line(overlay_mesh, d, a)


func _add_line(overlay_mesh: ImmediateMesh, from: Vector3, to: Vector3) -> void:
	overlay_mesh.surface_add_vertex(from)
	overlay_mesh.surface_add_vertex(to)
