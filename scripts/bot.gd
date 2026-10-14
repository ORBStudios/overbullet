extends StaticBody3D

var health: int = 100

func take_damage(amount: int) -> void:
	health -= amount
	print("Target health: ", health)

	if health <= 0:
		queue_free()
