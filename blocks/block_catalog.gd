extends Node
class_name BlockCatalog

const BLOCK_PATHS := [
	"res://blocks/walls/armored_wall/armored_wall_block.tres",
	"res://blocks/weapons/basic_turret/basic_turret_block.tres",
	"res://blocks/utility/test_core/test_core_block.tres",
	"res://blocks/debug/mob_spawn_marker/mob_spawn_marker_block.tres",
]

var _blocks_by_id: Dictionary = {}
var _blocks: Array[BlockDefinition] = []


func _ready() -> void:
	load_catalog()


func load_catalog() -> void:
	_blocks.clear()
	_blocks_by_id.clear()

	for path in BLOCK_PATHS:
		var definition := load(path) as BlockDefinition
		if definition == null:
			push_warning("Block catalog could not load %s" % path)
			continue
		if not definition.is_valid_definition():
			push_warning("Block definition is incomplete: %s" % path)
			continue

		_blocks.append(definition)
		_blocks_by_id[definition.id] = definition


func get_all_blocks() -> Array[BlockDefinition]:
	return _blocks.duplicate()


func get_block(id: StringName) -> BlockDefinition:
	return _blocks_by_id.get(id)


func get_blocks_in_category(category: String) -> Array[BlockDefinition]:
	var matches: Array[BlockDefinition] = []
	for definition in _blocks:
		if definition.category == category:
			matches.append(definition)

	return matches
