extends Node3D

@export var world_grid_path: NodePath
@export var cell_size := 1.0
@export var tile_thickness := 0.1

var _flat_material: StandardMaterial3D
var _raised_material: StandardMaterial3D
var _ramp_material: StandardMaterial3D
var _blocked_material: StandardMaterial3D


func _ready() -> void:
	_create_materials()
	call_deferred("rebuild")


func rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var world_grid := get_node_or_null(world_grid_path)
	if world_grid == null:
		push_warning("TerrainTestArena needs a WorldGrid node")
		return

	var cells: Dictionary = world_grid.get_all_cells()
	var grid_size: Vector2i = world_grid.grid_size
	var half_size := Vector2(grid_size) * cell_size * 0.5

	for cell: Vector2i in cells:
		var data: Dictionary = cells[cell]
		_create_cell_visual(cell, data, half_size)


func _create_materials() -> void:
	_flat_material = _make_material(Color(0.28, 0.42, 0.32, 1))
	_raised_material = _make_material(Color(0.38, 0.46, 0.36, 1))
	_ramp_material = _make_material(Color(0.58, 0.52, 0.28, 1))
	_blocked_material = _make_material(Color(0.24, 0.22, 0.24, 1))


func _create_cell_visual(cell: Vector2i, data: Dictionary, half_size: Vector2) -> void:
	var height := int(data.get("height", 0))
	var walkable := bool(data.get("walkable", true))
	var slope_type : StringName = data.get("slope_type", WorldGrid.SLOPE_FLAT)
	var visual_height : float = max(tile_thickness, float(height) + tile_thickness)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(cell_size, visual_height, cell_size)
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(
		(float(cell.x) + 0.5) * cell_size - half_size.x,
		visual_height * 0.5 - tile_thickness,
		(float(cell.y) + 0.5) * cell_size - half_size.y
	)
	mesh_instance.material_override = _get_material(walkable, slope_type, height)
	add_child(mesh_instance)


func _get_material(walkable: bool, slope_type: StringName, height: int) -> StandardMaterial3D:
	if not walkable:
		return _blocked_material
	if slope_type == WorldGrid.SLOPE_RAMP:
		return _ramp_material
	if height > 0:
		return _raised_material

	return _flat_material


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
