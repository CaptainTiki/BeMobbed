extends Node

signal dev_mode_changed(enabled: bool)

@export var status_label_path: NodePath

var dev_mode_enabled := true:
	set(value):
		if dev_mode_enabled == value:
			return

		dev_mode_enabled = value
		_update_status_label()
		dev_mode_changed.emit(dev_mode_enabled)

@onready var _status_label: Label = get_node_or_null(status_label_path)


func _ready() -> void:
	_update_status_label()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_toggle_mode"):
		dev_mode_enabled = not dev_mode_enabled


func is_dev_mode_enabled() -> bool:
	return dev_mode_enabled


func _update_status_label() -> void:
	if _status_label == null:
		return

	_status_label.text = "DEV MODE ON" if dev_mode_enabled else "DEV MODE OFF"
