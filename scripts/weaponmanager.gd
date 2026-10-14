
extends Node3D

# Current weapon stats
const FIRERATE = 0.15
const MAGSIZE = 22
const RELOADTIME = 1.2
const DAMAGE = 10

var ammo: int = MAGSIZE
var isreloading: bool = false
var canshoot: bool = true

@onready var ray: RayCast3D = $"../RayCast3D"


func _process(_delta: float) -> void:
	# Reload
	if Input.is_action_just_pressed("reload"):
		reload_weapon()

	# Fire
	if Input.is_action_pressed("fire"):
		if canshoot and not isreloading and ammo > 0:
			shoot()


func shoot() -> void:
	canshoot = false
	ammo -= 1

	ray.force_raycast_update()

	if ray.is_colliding():
		var obj = ray.get_collider()

		if obj.has_method("take_damage"):
			obj.take_damage(DAMAGE)

	print("Ammo: ", ammo, "/", MAGSIZE)

	await get_tree().create_timer(FIRERATE).timeout
	canshoot = true


func reload_weapon() -> void:
	if isreloading or ammo == MAGSIZE:
		return

	isreloading = true
	canshoot = false

	print("Reloading...")

	await get_tree().create_timer(RELOADTIME).timeout

	ammo = MAGSIZE
	isreloading = false
	canshoot = true

	print("Reloaded! Ammo: ", ammo, "/", MAGSIZE)
