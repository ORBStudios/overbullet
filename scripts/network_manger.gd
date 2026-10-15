
extends Node

const PORT := 9999

var PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

@onready var players: Node = $"../players"
@onready var spawner: MultiplayerSpawner = $"../MultiplayerSpawner"


func _ready() -> void:
	spawner.spawn_function = spawn_custom_player

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	if "--server" in OS.get_cmdline_user_args():
		start_server()


func start_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT)

	if error != OK:
		push_error("Server failed to start: %s" % error)
		return

	multiplayer.multiplayer_peer = peer
	print("SERVER STARTED | Port: ", PORT)


func join_server(address: String = "127.0.0.1") -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, PORT)

	if error != OK:
		push_error("Could not start client connection: %s" % error)
		return

	multiplayer.multiplayer_peer = peer
	print("Connecting to: ", address)


func disconnect_from_server() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	print("Disconnected.")


func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)

	if multiplayer.is_server():
		spawn_player(id)


func spawn_player(id: int) -> void:
	if not multiplayer.is_server():
		return

	spawner.spawn(id)


func spawn_custom_player(data: Variant) -> Node:
	var id := int(data)

	var player = PLAYER_SCENE.instantiate()
	player.name = str(id)
	player.userID = str(id)
	player.set_multiplayer_authority(id)

	print("Creating player: ", id)
	return player


@rpc("any_peer", "reliable")
func sumit_username(username: String) -> void:
	if not multiplayer.is_server():
		return

	var sender_id := multiplayer.get_remote_sender_id()
	var player = players.get_node_or_null(str(sender_id))

	if player:
		player.username = username
		print("Username received: ", username)


func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)

	if not multiplayer.is_server():
		return

	var player = players.get_node_or_null(str(id))

	if player:
		player.queue_free()


func _on_connected() -> void:
	print("Connected to server!")

	$"../GameUI/TempMenu".visible = false
	$"../GameUI/HUD".visible = true

	var username: String = $"../GameUI/TempMenu/TextEdit".text.strip_edges()
	if username.is_empty():
		username = "Player"

	sumit_username.rpc_id(1, username)


func _on_connection_failed() -> void:
	print("Connection failed.")


func _on_server_disconnected() -> void:
	print("Server disconnected.")


func _on_button_pressed() -> void:
	var inputip: String = $"../GameUI/TempMenu/TextEdit".text.strip_edges()

	if inputip.is_empty():
		join_server()
	else:
		join_server(inputip)
