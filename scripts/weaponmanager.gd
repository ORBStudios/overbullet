
extends Node3D

const WEAPON_SCENES: Array[PackedScene] = [
	preload("res://weapons/smg.tscn"),
	preload("res://weapons/pistol.tscn")
]

const WEAPON_CONFIG: Array[Weapon] = [
	preload("res://weapons/smg.tres"),
	preload("res://weapons/pistol.tres")
]

var weaponnow: int = 0
var current_weapon: Node3D

var ammos := {}

var isdrawing: bool = false
var isreloading: bool = false
var canshoot: bool = true

# Changes whenever a new weapon is selected.
var weapon_switch_id: int = 0

@onready var GameManager = get_tree().current_scene.get_node_or_null("%GameManager")

@onready var ray: RayCast3D = $"../RayCast3D"
@onready var hud: CanvasLayer = get_tree().current_scene.get_node_or_null("%GameUI")
@onready var player = $"../../.."

func _ready() -> void:
	for i in range(WEAPON_CONFIG.size()):
		var config = WEAPON_CONFIG[i]
		ammos[i] = {
			"mag": config.magazine_size,
			"reserve": config.reserve_ammo
		}

	call_deferred("equip_weapon", weaponnow)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("switch prev"):
		switch_weapon(-1)

	if Input.is_action_just_pressed("switch next"):
		switch_weapon(1)

	if Input.is_action_just_pressed("reload"):
		reload_weapon()

	if Input.is_action_pressed("fire"):
		shoot()


func switch_weapon(direction: int) -> void:
	# Reloading cannot be interrupted for now.
	if isreloading:
		return

	var next_index := (
		weaponnow + direction + WEAPON_SCENES.size()
	) % WEAPON_SCENES.size()

	equip_weapon(next_index)

func equip_weapon(index: int) -> void:
	if isreloading:
		return

	if index == weaponnow and current_weapon != null:
		return

	# Invalidate timers belonging to previous weapon switches.
	weapon_switch_id += 1
	var my_switch_id := weapon_switch_id

	isdrawing = true
	canshoot = false

	if current_weapon != null:
		current_weapon.hide()
		current_weapon.queue_free()

	weaponnow = index
	current_weapon = WEAPON_SCENES[index].instantiate() as Node3D

	# Add while hidden to prevent the idle-pose flash.
	current_weapon.hide()
	add_child(current_weapon)

	var anim = current_weapon.find_child(
		"AnimationPlayer", true, false
	)

	if anim:
		anim.stop()

		if weaponnow == 0:
			anim.play("animation_model_draw")
		elif weaponnow == 1:
			anim.play("Arms|draw")

		# Apply the starting Draw pose immediately.
		anim.advance(0)

	current_weapon.show()

	update_ammo_hud()

	print("Equipping: ", current_weapon.name)

	await get_tree().create_timer(
		WEAPON_CONFIG[index].draw
	).timeout

	# Ignore an outdated Draw timer.
	if my_switch_id != weapon_switch_id:
		return

	isdrawing = false
	canshoot = true

	print("Ready: ", current_weapon.name)


func update_ammo_hud() -> void:
	var hud_node = get_tree().root.find_child("GameUI", true, false)

	if hud_node == null:
		push_error("HUD not found in the running scene tree!")
		return

	if not hud_node.has_method("ammoupdate"):
		push_error("HUD exists, but ammoupdate() was not found!")
		return

	var ammodat = ammos[weaponnow]
	hud_node.ammoupdate(ammodat["mag"], ammodat["reserve"])

@rpc("any_peer","reliable")
func req_shoot(pos,dir):
	if not multiplayer.is_server():
		return
	var shooter_id = multiplayer.get_remote_sender_id()
	var raycast = PhysicsRayQueryParameters3D.create(pos, pos+dir.normalized()*100)
	var result = get_world_3d().direct_space_state.intersect_ray(raycast)
	if result.collider is Player:
		if $players.get_node_or_null(str(shooter_id)).team != result.collider():
			GameManager.apply_damage(result.collider,5) #temp damage h
	
func shoot() -> void:
	var ammodat = ammos[weaponnow]

	if isdrawing or isreloading or not canshoot:
		return

	if ammodat["mag"] <= 0:
		return

	canshoot = false

	var config = WEAPON_CONFIG[weaponnow]
	var shot_switch_id := weapon_switch_id

	ammodat["mag"] -= 1

	var anim = current_weapon.find_child(
		"AnimationPlayer", true, false
	)

	if anim:
		anim.stop()
		if weaponnow == 0:
			anim.play("animation_model_Shootauto")
		else:
			anim.play("Arms|shoot")

	req_shoot.rpc_id(1, player.head.global_position, -player.head.global_transform.basis.z)
	#ray.force_raycast_update()
#
	#if ray.is_colliding():
		#var obj = ray.get_collider()
#
		#if obj.has_method("take_damage"):
			#obj.take_damage(config.damage)
			
	

	print(
		"Ammo: ",
		ammodat["mag"],
		"/",
		ammodat["reserve"]
	)

	update_ammo_hud()

	await get_tree().create_timer(config.fire_rate).timeout

	# An old shot timer must not unlock a weapon
	# that is currently being drawn or reloaded.
	if shot_switch_id != weapon_switch_id:
		return

	if not isdrawing and not isreloading:
		canshoot = true


func reload_weapon() -> void:
	if isdrawing or isreloading:
		return

	var config = WEAPON_CONFIG[weaponnow]
	var ammodat = ammos[weaponnow]

	if ammodat["mag"] == config.magazine_size:
		return

	if ammodat["reserve"] <= 0:
		return

	isreloading = true
	canshoot = false

	var anim = current_weapon.find_child(
		"AnimationPlayer", true, false
	)

	if anim:
		anim.stop()
		if weaponnow == 0:
			anim.play("animation_model_reload")
		else:
			anim.play("Arms|reload")

	print("Reloading...")

	await get_tree().create_timer(config.reload_time).timeout

	var loaded = min(
		config.magazine_size - ammodat["mag"],
		ammodat["reserve"]
	)

	ammodat["mag"] += loaded
	ammodat["reserve"] -= loaded

	isreloading = false
	canshoot = true

	print(
		"Reloaded! Ammo: ",
		ammodat["mag"],
		"/",
		ammodat["reserve"]
	)

	update_ammo_hud()
