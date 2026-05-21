extends PanelContainer
class_name GenericHotbar

signal entry_selected(slot_index: int, entry: HotbarEntry)

const SLOT_COUNT := 10
const STARTING_BLOCK_IDS: Array[StringName] = [
	&"armored_wall",
	&"basic_turret",
	&"test_core",
	&"mob_spawn_marker",
]

@export var catalog_path: NodePath

@onready var _slot_container: HBoxContainer = %SlotContainer

var _slots: Array[Button] = []
var _entries: Array[HotbarEntry] = []
var _selected_slot := 0
var _catalog: BlockCatalog


func _ready() -> void:
	_catalog = get_node_or_null(catalog_path)
	_entries.resize(SLOT_COUNT)
	for index in range(SLOT_COUNT):
		_entries[index] = HotbarEntry.empty()
		_create_slot_button(index)

	_populate_starting_entries()
	select_slot(0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var slot_index := _keycode_to_slot_index(event.keycode)
	if slot_index < 0:
		return

	select_slot(slot_index)
	get_viewport().set_input_as_handled()


func set_slot_entry(slot_index: int, entry: HotbarEntry) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return

	_entries[slot_index] = entry if entry != null else HotbarEntry.empty()
	_update_slot_button(slot_index)


func select_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return

	_selected_slot = slot_index
	for index in range(_slots.size()):
		_slots[index].button_pressed = index == _selected_slot

	entry_selected.emit(_selected_slot, _entries[_selected_slot])


func get_selected_entry() -> HotbarEntry:
	return _entries[_selected_slot]


func _create_slot_button(slot_index: int) -> void:
	var button := Button.new()
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(72, 54)
	button.text = _slot_label(slot_index)
	button.pressed.connect(select_slot.bind(slot_index))
	_slot_container.add_child(button)
	_slots.append(button)


func _update_slot_button(slot_index: int) -> void:
	var entry := _entries[slot_index]
	var label := _slot_label(slot_index)
	if entry != null and not entry.is_empty():
		label += "\n%s" % entry.display_name

	_slots[slot_index].text = label


func _populate_starting_entries() -> void:
	if _catalog == null:
		return

	for index in range(STARTING_BLOCK_IDS.size()):
		var definition := _catalog.get_block(STARTING_BLOCK_IDS[index])
		if definition != null:
			set_slot_entry(index, HotbarEntry.from_block(definition))


func _slot_label(slot_index: int) -> String:
	return str(slot_index + 1 if slot_index < 9 else 0)


func _keycode_to_slot_index(keycode: Key) -> int:
	if keycode >= KEY_1 and keycode <= KEY_9:
		return int(keycode - KEY_1)
	if keycode == KEY_0:
		return 9

	return -1
