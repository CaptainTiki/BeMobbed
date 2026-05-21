extends CharacterBody3D

@export var move_speed := 10.0
@export var fast_move_multiplier := 3.0
@export var mouse_sensitivity := 0.0025

@onready var camera: Camera3D = $Camera3D

var _pitch := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clamp(_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-89.0), deg_to_rad(89.0))
		camera.rotation.x = _pitch

	if event.is_action_pressed("player_release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("player_capture_mouse") and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(_delta: float) -> void:
	var input_dir := Vector3.ZERO

	if Input.is_action_pressed("player_move_forward"):
		input_dir -= basis.z
	if Input.is_action_pressed("player_move_back"):
		input_dir += basis.z
	if Input.is_action_pressed("player_move_left"):
		input_dir -= basis.x
	if Input.is_action_pressed("player_move_right"):
		input_dir += basis.x
	if Input.is_action_pressed("player_move_up"):
		input_dir += Vector3.UP
	if Input.is_action_pressed("player_move_down"):
		input_dir -= Vector3.UP

	var speed := move_speed
	if Input.is_action_pressed("player_move_fast"):
		speed *= fast_move_multiplier

	velocity = input_dir.normalized() * speed if input_dir.length_squared() > 0.0 else Vector3.ZERO
	move_and_slide()
