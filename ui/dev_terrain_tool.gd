extends PanelContainer

@export var terrain_editor_path: NodePath
@export var dev_mode_manager_path: NodePath

@onready var _mode_button: OptionButton = %ModeButton
@onready var _mode_hint: Label = %ModeHint
@onready var _save_name_edit: LineEdit = %SaveNameEdit
@onready var _save_button: Button = %SaveButton
@onready var _save_status: Label = %SaveStatus

var _terrain_editor: TerrainDevEditor
var _dev_mode_manager: Node


func _ready() -> void:
	_terrain_editor = get_node_or_null(terrain_editor_path)
	_dev_mode_manager = get_node_or_null(dev_mode_manager_path)
	_populate_modes()
	_connect_dev_mode()
	_connect_mode_button()
	_connect_save_button()
	_apply_mode(TerrainDevEditor.ToolMode.NONE)
	_update_dev_visibility()


func _populate_modes() -> void:
	_mode_button.clear()
	_mode_button.add_item("None", TerrainDevEditor.ToolMode.NONE)
	_mode_button.add_item("Height", TerrainDevEditor.ToolMode.HEIGHT)
	_mode_button.add_item("Flatten", TerrainDevEditor.ToolMode.FLATTEN)
	_mode_button.add_item("Slope", TerrainDevEditor.ToolMode.SLOPE)
	_mode_button.select(0)


func _connect_dev_mode() -> void:
	if _dev_mode_manager == null:
		return
	if _dev_mode_manager.has_signal("dev_mode_changed"):
		_dev_mode_manager.dev_mode_changed.connect(_on_dev_mode_changed)


func _connect_mode_button() -> void:
	_mode_button.item_selected.connect(_on_mode_selected)


func _connect_save_button() -> void:
	_save_button.pressed.connect(_on_save_pressed)


func _on_dev_mode_changed(_enabled: bool) -> void:
	_update_dev_visibility()


func _update_dev_visibility() -> void:
	if _dev_mode_manager == null:
		visible = true
		return

	visible = _dev_mode_manager.is_dev_mode_enabled()


func _on_mode_selected(index: int) -> void:
	_apply_mode(_mode_button.get_item_id(index))


func _apply_mode(mode: int) -> void:
	if _terrain_editor != null:
		_terrain_editor.set_tool_mode(mode)

	match mode:
		TerrainDevEditor.ToolMode.NONE:
			_mode_hint.text = "Mouse editing disabled."
		TerrainDevEditor.ToolMode.HEIGHT:
			_mode_hint.text = "Left raises. Right lowers."
		TerrainDevEditor.ToolMode.FLATTEN:
			_mode_hint.text = "Click and drag to match start height."
		TerrainDevEditor.ToolMode.SLOPE:
			_mode_hint.text = "Click creates slope. R rotates hovered cell."


func _on_save_pressed() -> void:
	if _terrain_editor == null:
		_save_status.text = "No terrain editor."
		return

	var terrain_name := _save_name_edit.text.strip_edges()
	if terrain_name == "":
		_save_status.text = "Enter a file name."
		return

	var saved := _terrain_editor.save_current_terrain(terrain_name)
	_save_status.text = "Saved." if saved else "Save failed."
