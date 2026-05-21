extends Resource
class_name HotbarEntry

enum EntryType {
	NONE,
	BLOCK,
	WEAPON,
	TOOL,
	CONSUMABLE,
	ABILITY,
}

@export var entry_type := EntryType.NONE
@export var display_name := ""
@export var block_definition: BlockDefinition


static func empty() -> HotbarEntry:
	var entry := HotbarEntry.new()
	entry.entry_type = EntryType.NONE
	return entry


static func from_block(definition: BlockDefinition) -> HotbarEntry:
	var entry := HotbarEntry.new()
	entry.entry_type = EntryType.BLOCK
	entry.block_definition = definition
	entry.display_name = definition.display_name if definition != null else ""
	return entry


func is_empty() -> bool:
	return entry_type == EntryType.NONE
