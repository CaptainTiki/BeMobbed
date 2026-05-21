extends PanelContainer
class_name BlockMenu

signal block_selected(definition: BlockDefinition)

@export var catalog_path: NodePath

@onready var _list: VBoxContainer = %BlockList

var _catalog: BlockCatalog


func _ready() -> void:
	_catalog = get_node_or_null(catalog_path)
	visible = false
	call_deferred("_populate")


func toggle() -> void:
	visible = not visible


func open() -> void:
	visible = true


func close() -> void:
	visible = false


func _populate() -> void:
	if _catalog == null:
		return

	for child in _list.get_children():
		child.queue_free()

	for definition in _catalog.get_all_blocks():
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(220, 38)
		button.text = "%s  /  %s" % [definition.display_name, definition.category]
		button.pressed.connect(_select_block.bind(definition))
		_list.add_child(button)


func _select_block(definition: BlockDefinition) -> void:
	block_selected.emit(definition)
	close()
