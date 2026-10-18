extends Node3D

var player
enum TEAM {
	BLUE,
	RED
}
var PLAYERS = []

func _ready() -> void:
	pass


func player_join(player):
	PLAYERS.append(player)
	player.team = TEAM.BLUE if PLAYERS.size() %2 == 0 else TEAM.RED
	
func _process(delta: float) -> void:
	pass

func apply_damage(player,damage):
	if not multiplayer.is_server():
		return
		
	player.take_damage(damage)
	print("damage ",str(player.health))
	
