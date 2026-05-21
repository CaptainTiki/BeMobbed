extends RefCounted
class_name TerrainSurface


static func get_top_corner_heights(data: Dictionary) -> PackedFloat32Array:
	var height := float(data.get("height", 0))
	var slope_type: StringName = data.get("slope_type", WorldGrid.SLOPE_FLAT)
	var slope_direction := int(data.get("slope_direction", WorldGrid.DIRECTION_NORTH))
	var top_heights := PackedFloat32Array([height, height, height, height])

	if slope_type == WorldGrid.SLOPE_STRAIGHT:
		_apply_straight_slope_heights(top_heights, height, slope_direction)
	elif slope_type == WorldGrid.SLOPE_CORNER:
		_apply_corner_slope_heights(top_heights, height, slope_direction)

	return top_heights


static func is_slope(data: Dictionary) -> bool:
	var slope_type: StringName = data.get("slope_type", WorldGrid.SLOPE_FLAT)
	return slope_type == WorldGrid.SLOPE_STRAIGHT or slope_type == WorldGrid.SLOPE_CORNER


static func get_edge_heights(data: Dictionary, direction: int) -> PackedFloat32Array:
	var heights := get_top_corner_heights(data)

	match direction:
		WorldGrid.DIRECTION_NORTH:
			return PackedFloat32Array([heights[0], heights[1]])
		WorldGrid.DIRECTION_EAST:
			return PackedFloat32Array([heights[1], heights[2]])
		WorldGrid.DIRECTION_SOUTH:
			return PackedFloat32Array([heights[2], heights[3]])
		WorldGrid.DIRECTION_WEST:
			return PackedFloat32Array([heights[3], heights[0]])

	return PackedFloat32Array([heights[0], heights[1]])


static func get_edge_average_height(data: Dictionary, direction: int) -> float:
	var edge_heights := get_edge_heights(data, direction)
	return (edge_heights[0] + edge_heights[1]) * 0.5


static func get_shared_edge_height_delta(from_data: Dictionary, to_data: Dictionary, direction: int) -> float:
	var from_heights := get_edge_heights(from_data, direction)
	var to_heights := get_edge_heights(to_data, _opposite_direction(direction))
	return max(abs(from_heights[0] - to_heights[1]), abs(from_heights[1] - to_heights[0]))


static func _opposite_direction(direction: int) -> int:
	return (direction + 2) % 4


static func _apply_straight_slope_heights(top_heights: PackedFloat32Array, height: float, slope_direction: int) -> void:
	var high := height + 1.0
	match slope_direction:
		WorldGrid.DIRECTION_NORTH:
			top_heights[0] = high
			top_heights[1] = high
		WorldGrid.DIRECTION_EAST:
			top_heights[1] = high
			top_heights[2] = high
		WorldGrid.DIRECTION_SOUTH:
			top_heights[2] = high
			top_heights[3] = high
		WorldGrid.DIRECTION_WEST:
			top_heights[0] = high
			top_heights[3] = high


static func _apply_corner_slope_heights(top_heights: PackedFloat32Array, height: float, slope_direction: int) -> void:
	var high := height + 1.0
	match slope_direction:
		WorldGrid.DIRECTION_NORTH:
			top_heights[0] = high
		WorldGrid.DIRECTION_EAST:
			top_heights[1] = high
		WorldGrid.DIRECTION_SOUTH:
			top_heights[2] = high
		WorldGrid.DIRECTION_WEST:
			top_heights[3] = high
