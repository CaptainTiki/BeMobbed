extends Resource
class_name BlockDefinition

@export var id: StringName
@export var display_name := ""
@export var category := ""
@export_multiline var description := ""
@export var scene: PackedScene
@export var footprint := Vector2i.ONE
@export var blocks_building := true
@export var blocks_movement := true
@export var requires_flat_ground := true


func is_valid_definition() -> bool:
	return id != &"" and scene != null and footprint.x > 0 and footprint.y > 0
