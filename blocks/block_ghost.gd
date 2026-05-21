extends Node3D
class_name BlockGhost

@export var cell_size := 1.0

var _mesh_instance: MeshInstance3D
var _valid_material: StandardMaterial3D
var _invalid_material: StandardMaterial3D
var _definition: BlockDefinition


func _ready() -> void:
	_create_materials()
	_create_mesh_instance()
	visible = false


func set_definition(definition: BlockDefinition) -> void:
	_definition = definition
	if _mesh_instance == null:
		return

	if definition == null:
		visible = false
		return

	var mesh := BoxMesh.new()
	mesh.size = Vector3(
		float(definition.footprint.x) * cell_size * 0.92,
		0.9,
		float(definition.footprint.y) * cell_size * 0.92
	)
	_mesh_instance.mesh = mesh


func update_preview(world_position: Vector3, is_valid: bool) -> void:
	if _definition == null:
		visible = false
		return

	global_position = world_position + Vector3(0.0, 0.45, 0.0)
	_mesh_instance.material_override = _valid_material if is_valid else _invalid_material
	visible = true


func hide_preview() -> void:
	visible = false


func _create_mesh_instance() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "PreviewMesh"
	add_child(_mesh_instance)


func _create_materials() -> void:
	_valid_material = _make_material(Color(0.1, 0.95, 0.45, 0.38))
	_invalid_material = _make_material(Color(1.0, 0.18, 0.12, 0.42))


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
