
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
var isreloading: bool = false
var canshoot: bool = true


@onready var ray: RayCast3D = $"../RayCast3D"
@onready var hud = get_tree().root.get_node("root/GameUI")

func _ready() -> void:
	for i in range(WEAPON_CONFIG.size()):
		var config = WEAPON_CONFIG[i]
		ammos[i] = {"mag":config.magazine_size,"reserve":config.reserve_ammo} 
	call_deferred("equip_weapon",weaponnow)

func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if Input.is_action_just_pressed("switch prev"):
		switch_weapon(-1)

	if Input.is_action_just_pressed("switch next"):
		switch_weapon(1)

	if Input.is_action_just_pressed("reload"):
		reload_weapon()

	if Input.is_action_pressed("fire"):
		shoot()


func switch_weapon(direction: int) -> void:
	if not is_multiplayer_authority():
		return
	if isreloading:
		return
	var next_index := (
		weaponnow + direction + WEAPON_SCENES.size()
	) % WEAPON_SCENES.size()

	equip_weapon(next_index)


func equip_weapon(index: int) -> void:
	if current_weapon != null:
		current_weapon.queue_free()

	weaponnow = index
	current_weapon = WEAPON_SCENES[index].instantiate() as Node3D
	add_child(current_weapon)
	var anim = current_weapon.find_child("AnimationPlayer",true,false)
	canshoot = false
	if anim:
		anim.stop()
		if weaponnow == 0:
			anim.play("animation_model_draw")
		elif weaponnow == 1:
			anim.play("Arms|draw")
	var ammodat = ammos[weaponnow]
	hud.ammoupdate(ammodat["mag"],ammodat["reserve"])
	await get_tree().create_timer(WEAPON_CONFIG[weaponnow].draw).timeout
	canshoot = true
	print("Equipped: ", current_weapon.name)
	
func shoot() -> void:
	if not is_multiplayer_authority():
		return
	var ammodat = ammos[weaponnow]
	if not canshoot or isreloading or ammodat["mag"] <= 0:
		return
	canshoot = false
	var anim = current_weapon.find_child("AnimationPlayer",true,false)
	if anim:
		anim.stop()
		if weaponnow == 0:
			anim.play("animation_model_Shootauto")
		elif weaponnow == 1:
			anim.play("Arms|shoot")
			
	var config = WEAPON_CONFIG[weaponnow]
	ammodat["mag"] -= 1

	ray.force_raycast_update()

	if ray.is_colliding():
		var obj = ray.get_collider()

		if obj.has_method("take_damage"):
			obj.take_damage(config.damage)

	print("Ammo: ", ammodat["mag"], "/", ammodat["reserve"])
	hud.ammoupdate(ammodat["mag"],ammodat["reserve"])
	await get_tree().create_timer(config.fire_rate).timeout
	canshoot = true

func reload_weapon() -> void:
	if not is_multiplayer_authority():
		return
	var config = WEAPON_CONFIG[weaponnow]
	var ammodat = ammos[weaponnow]
	if isreloading or ammodat["mag"] == config.magazine_size or ammodat["reserve"] <= 0:
		return

	isreloading = true
	canshoot = false

	print("Reloading...")
	var anim = current_weapon.find_child("AnimationPlayer",true,false)
	if anim:
		anim.stop()
		if weaponnow == 0:
			anim.play("animation_model_reload")
		elif weaponnow == 1:
			anim.play("Arms|reload")
	await get_tree().create_timer(config.reload_time).timeout
	var loaded = min(config.magazine_size - ammodat["mag"], ammodat["reserve"])
	ammodat["mag"] += loaded
	ammodat["reserve"] -= loaded
	isreloading = false
	canshoot = true

	print("Reloaded! Ammo: ", ammodat["mag"], "/", ammodat["reserve"])
	hud.ammoupdate(ammodat["mag"],ammodat["reserve"])
