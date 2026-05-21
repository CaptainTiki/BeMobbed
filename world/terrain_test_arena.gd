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
	if not world_grid.terrain_changed.is_connected(rebuild):
		world_grid.terrain_changed.connect(rebuild)

	var cells: Dictionary = world_grid.get_all_cells()
	var grid_size: Vector2i = world_grid.grid_size
	var half_size := Vector2(grid_size) * cell_size * 0.5

	for cell: Vector2i in cells:
		var data: Dictionary = cells[cell]
		_create_cell_visual(cell, data, cells, half_size)


func _create_materials() -> void:
	_flat_material = _make_material(Color(0.28, 0.42, 0.32, 1))
	_raised_material = _make_material(Color(0.38, 0.46, 0.36, 1))
	_ramp_material = _make_material(Color(0.58, 0.52, 0.28, 1))
	_blocked_material = _make_material(Color(0.24, 0.22, 0.24, 1))


func _create_cell_visual(cell: Vector2i, data: Dictionary, all_cells: Dictionary, half_size: Vector2) -> void:
	var height := int(data.get("height", 0))
	var walkable := bool(data.get("walkable", true))
	var slope_type : StringName = data.get("slope_type", WorldGrid.SLOPE_FLAT)
	var is_slope : bool = TerrainSurface.is_slope(data)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _create_slope_mesh(cell, data, all_cells) if is_slope else _create_box_mesh(height)
	mesh_instance.position = Vector3(
		(float(cell.x) + 0.5) * cell_size - half_size.x,
		0.0 if is_slope else _get_box_center_y(height),
		(float(cell.y) + 0.5) * cell_size - half_size.y
	)
	mesh_instance.material_override = _get_material(walkable, slope_type, height)
	add_child(mesh_instance)


func _create_box_mesh(height: int) -> BoxMesh:
	var visual_height : float = max(tile_thickness, float(height) + tile_thickness)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(cell_size, visual_height, cell_size)
	return mesh


func _get_box_center_y(height: int) -> float:
	var visual_height : float = max(tile_thickness, float(height) + tile_thickness)
	return visual_height * 0.5 - tile_thickness


func _create_slope_mesh(cell: Vector2i, data: Dictionary, all_cells: Dictionary) -> ArrayMesh:
	var half_cell := cell_size * 0.5
	var bottom_y := -tile_thickness
	var top_heights := TerrainSurface.get_top_corner_heights(data)
	var top_north_west := Vector3(-half_cell, top_heights[0], -half_cell)
	var top_north_east := Vector3(half_cell, top_heights[1], -half_cell)
	var top_south_east := Vector3(half_cell, top_heights[2], half_cell)
	var top_south_west := Vector3(-half_cell, top_heights[3], half_cell)
	var bottom_north_west := Vector3(-half_cell, bottom_y, -half_cell)
	var bottom_north_east := Vector3(half_cell, bottom_y, -half_cell)
	var bottom_south_east := Vector3(half_cell, bottom_y, half_cell)
	var bottom_south_west := Vector3(-half_cell, bottom_y, half_cell)
	var exposed_edges := _get_exposed_edges(cell, data, all_cells)
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	_add_oriented_quad(
		surface_tool,
		top_north_west,
		top_north_east,
		top_south_east,
		top_south_west,
		Vector3.UP
	)
	_add_oriented_quad(
		surface_tool,
		bottom_north_west,
		bottom_south_west,
		bottom_south_east,
		bottom_north_east,
		Vector3.DOWN
	)
	if exposed_edges["north"]:
		_add_oriented_quad(
			surface_tool,
			bottom_north_west,
			bottom_north_east,
			top_north_east,
			top_north_west,
			Vector3.FORWARD
		)
	if exposed_edges["east"]:
		_add_oriented_quad(
			surface_tool,
			bottom_north_east,
			bottom_south_east,
			top_south_east,
			top_north_east,
			Vector3.RIGHT
		)
	if exposed_edges["south"]:
		_add_oriented_quad(
			surface_tool,
			bottom_south_east,
			bottom_south_west,
			top_south_west,
			top_south_east,
			Vector3.BACK
		)
	if exposed_edges["west"]:
		_add_oriented_quad(
			surface_tool,
			bottom_south_west,
			bottom_north_west,
			top_north_west,
			top_south_west,
			Vector3.LEFT
		)

	return surface_tool.commit()


func _get_exposed_edges(cell: Vector2i, data: Dictionary, all_cells: Dictionary) -> Dictionary:
	return {
		"north": not _edge_matches_neighbor(data, all_cells.get(cell + Vector2i(0, -1), {}), "north"),
		"east": not _edge_matches_neighbor(data, all_cells.get(cell + Vector2i(1, 0), {}), "east"),
		"south": not _edge_matches_neighbor(data, all_cells.get(cell + Vector2i(0, 1), {}), "south"),
		"west": not _edge_matches_neighbor(data, all_cells.get(cell + Vector2i(-1, 0), {}), "west"),
	}


func _edge_matches_neighbor(data: Dictionary, neighbor_data: Dictionary, edge: String) -> bool:
	if neighbor_data.is_empty():
		return false

	var heights := TerrainSurface.get_edge_heights(data, _edge_name_to_direction(edge))
	var neighbor_heights := TerrainSurface.get_edge_heights(neighbor_data, _opposite_direction(_edge_name_to_direction(edge)))
	var tolerance := 0.001
	return abs(heights[0] - neighbor_heights[1]) <= tolerance and abs(heights[1] - neighbor_heights[0]) <= tolerance


func _edge_name_to_direction(edge: String) -> int:
	match edge:
		"north":
			return WorldGrid.DIRECTION_NORTH
		"east":
			return WorldGrid.DIRECTION_EAST
		"south":
			return WorldGrid.DIRECTION_SOUTH
		"west":
			return WorldGrid.DIRECTION_WEST

	return WorldGrid.DIRECTION_NORTH


func _opposite_direction(direction: int) -> int:
	return (direction + 2) % 4


func _add_oriented_quad(
	surface_tool: SurfaceTool,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	d: Vector3,
	expected_normal: Vector3
) -> void:
	var normal := (b - a).cross(c - a).normalized()
	var outward_normal := normal
	if outward_normal.dot(expected_normal) < 0.0:
		outward_normal = -outward_normal

	# Godot's visible front face for ArrayMesh triangles is the opposite winding
	# of the cross-product order used above, so winding and lighting normals are
	# handled separately here.
	if normal.dot(expected_normal) > 0.0:
		_add_triangle(surface_tool, a, d, c, outward_normal)
		_add_triangle(surface_tool, a, c, b, outward_normal)
		return

	_add_triangle(surface_tool, a, b, c, outward_normal)
	_add_triangle(surface_tool, a, c, d, outward_normal)


func _add_triangle(surface_tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	surface_tool.set_normal(normal)
	surface_tool.add_vertex(a)
	surface_tool.set_normal(normal)
	surface_tool.add_vertex(b)
	surface_tool.set_normal(normal)
	surface_tool.add_vertex(c)


func _get_material(walkable: bool, slope_type: StringName, height: int) -> StandardMaterial3D:
	if not walkable:
		return _blocked_material
	if slope_type == WorldGrid.SLOPE_STRAIGHT or slope_type == WorldGrid.SLOPE_CORNER:
		return _ramp_material
	if height > 0:
		return _raised_material

	return _flat_material


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
