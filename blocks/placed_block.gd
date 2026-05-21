extends Node3D
class_name PlacedBlock

@export var definition: BlockDefinition

var grid_cell := Vector2i(-1, -1)
var anchor_cell := Vector2i(-1, -1)
var block_id: StringName = &""
var footprint_cells: Array[Vector2i] = []


func setup(block_definition: BlockDefinition, cell: Vector2i, occupied_cells: Array[Vector2i]) -> void:
	definition = block_definition
	grid_cell = cell
	anchor_cell = cell
	block_id = definition.id if definition != null else &""
	footprint_cells = occupied_cells.duplicate()
