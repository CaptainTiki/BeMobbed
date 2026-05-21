extends Node3D
class_name Level

@export_file("*.json") var terrain_file_path := ""
@export var seed_test_arena_when_empty := true

@onready var world_grid: WorldGrid = $WorldGrid


func _ready() -> void:
	if terrain_file_path != "":
		var loaded := world_grid.load_terrain_file(terrain_file_path)
		if loaded:
			return

	if seed_test_arena_when_empty:
		world_grid.initialize_test_arena()
	else:
		world_grid.initialize_flat_grid()
