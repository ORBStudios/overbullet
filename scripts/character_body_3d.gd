class_name Player
extends CharacterBody3D

var username
var userID
var team

const SPEED = 7.0
const JUMP_VELOCITY = 6.0

# Movement
const GROUND_ACCEL = 14.0
const GROUND_FRICTION = 8.0
const STOP_SPEED = 2.0
const AIR_ACCEL = 0.5

const SENS = 0.002

var health: int = 100
var paused: bool = false

@onready var head: Node3D = $head
@onready var hud = get_tree().root.get_node("root/GameUI")


func _ready() -> void:
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		head.get_node("Camera3D").current = true
	else:
		head.get_node("Camera3D").current = false

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event is InputEventMouseMotion:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return

		var mouse_event := event as InputEventMouseMotion

		rotate_y(-mouse_event.relative.x * SENS)
		head.rotate_x(-mouse_event.relative.y * SENS)

		head.rotation.x = clamp(
			head.rotation.x,
			deg_to_rad(-89.0),
			deg_to_rad(89.0)
		)

func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	print("HP: ", health)
	hud.hpupdate(health)

	if health <= 0:
		print("Eliminated")



func respawn():
	if not multiplayer.is_server():
		return
	

# MOVEMENT

func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if Input.is_key_pressed(KEY_H):
		take_damage(1)
	if Input.is_action_just_pressed("exit"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Freeze horizontal movement while the menu is open
	if paused:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var input_dir := Input.get_vector(
		"left", "right", "forward", "back"
	)

	var wish_dir := (
		transform.basis
		* Vector3(input_dir.x, 0.0, input_dir.y)
	).normalized()

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var grounded := is_on_floor()

	if grounded:
		horizontal = _apply_friction(horizontal, delta)

		if wish_dir != Vector3.ZERO:
			horizontal = _accelerate(
				horizontal, wish_dir, SPEED, GROUND_ACCEL, delta
			)
	elif wish_dir != Vector3.ZERO:
		horizontal = _accelerate(
			horizontal, wish_dir, SPEED, AIR_ACCEL, delta
		)

	velocity.x = horizontal.x
	velocity.z = horizontal.z

	# Jump
	if Input.is_action_just_pressed("jump") and grounded:
		velocity.y = JUMP_VELOCITY

	move_and_slide()


func _apply_friction(
	horizontal: Vector3, delta: float
) -> Vector3:
	var speed := horizontal.length()

	if speed < 0.001:
		return Vector3.ZERO

	var control := maxf(speed, STOP_SPEED)
	var drop := control * GROUND_FRICTION * delta
	var new_speed := maxf(speed - drop, 0.0)

	return horizontal * (new_speed / speed)


func _accelerate(
	horizontal: Vector3,
	wish_dir: Vector3,
	wish_speed: float,
	acceleration: float,
	delta: float
) -> Vector3:
	var current_speed := horizontal.dot(wish_dir)
	var speed_to_add := wish_speed - current_speed

	if speed_to_add <= 0.0:
		return horizontal

	var acceleration_speed := acceleration * wish_speed * delta
	acceleration_speed = minf(acceleration_speed, speed_to_add)

	return horizontal + wish_dir * acceleration_speed
