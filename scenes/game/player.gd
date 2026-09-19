extends CharacterBody3D

const SPEED := 6.0
const JUMP_VELOCITY := 5.5
const GRAVITY := 18.0
const TURN_SPEED := 12.0

const MOUSE_SENSITIVITY := 0.005
const PITCH_MIN := -70.0
const PITCH_MAX := 70.0

const ZOOM_MIN := 1.5
const ZOOM_MAX := 3.0
const ZOOM_STEP := 1.0
const ZOOM_SMOOTHING := 10.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

var _target_zoom := 3.0
var _orbiting := false


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	camera.current = is_multiplayer_authority()
	set_process_unhandled_input(is_multiplayer_authority())


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				_set_orbiting(event.pressed)
			MOUSE_BUTTON_WHEEL_UP:
				_target_zoom = clampf(_target_zoom - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			MOUSE_BUTTON_WHEEL_DOWN:
				_target_zoom = clampf(_target_zoom + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)

	elif event is InputEventMouseMotion and _orbiting:
		camera_pivot.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		spring_arm.rotation.x = clampf(
			spring_arm.rotation.x - event.relative.y * MOUSE_SENSITIVITY,
			deg_to_rad(PITCH_MIN),
			deg_to_rad(PITCH_MAX)
		)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _orbiting:
		_set_orbiting(false)


func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	spring_arm.spring_length = lerpf(
		spring_arm.spring_length,
		_target_zoom,
		1.0 - exp(-ZOOM_SMOOTHING * delta)
	)


func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null or not is_multiplayer_authority():
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var yaw := Basis(Vector3.UP, camera_pivot.rotation.y)
	var direction := (yaw * Vector3(input.x, 0.0, input.y)).normalized()

	if direction.length() > 0.0:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		var target_yaw := atan2(-direction.x, -direction.z)
		mesh.rotation.y = lerp_angle(mesh.rotation.y, target_yaw, TURN_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()

	if global_position.y < -20.0:
		global_position = Vector3(0.0, 3.0, 0.0)
		velocity = Vector3.ZERO


func _set_orbiting(active: bool) -> void:
	_orbiting = active
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE
