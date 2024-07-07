extends Node

const PORT = 7000
const MAX_PLAYERS = 2

signal player_connected(peer_id)
signal player_disconnected(peer_id)
signal serverFull()
signal connection_failed()
signal connection_succeeded()
signal player_ready_changed(peer_id, is_ready)
signal players_sync(players_data)
signal game_started()

var peer = ENetMultiplayerPeer.new()
@export var players_ready = {}

func host_game():
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Server started")
	else:
		print("Failed to create server")

func join_game(ip_address):
	var error = peer.create_client(ip_address, PORT)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Attempting to connect to server")
	else:
		print("Failed to create client")
		connection_failed.emit()

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_peer_connected(id):
	print("Peer connected: " + str(id))
	if multiplayer.is_server() and multiplayer.get_peers().size() > MAX_PLAYERS - 1:
	# Server is full, disconnect the peer
		peer.disconnect_peer(id)
	else:
		player_connected.emit(id)
		players_ready[id] = false

func _on_peer_disconnected(id):
	print("Peer disconnected: " + str(id))
	player_disconnected.emit(id)
	players_ready.erase(id)

func _on_connected_to_server():
	print("Successfully connected to server")
	connection_succeeded.emit()
	

func _on_connection_failed():
	print("Failed to connect to server")
	connection_failed.emit()

func _on_server_disconnected():
	print("Server disconnected")
	# Handle server disconnection (e.g., return to main menu)

@rpc("any_peer", "call_local", "reliable")
func player_ready(is_ready):
	var id = multiplayer.get_remote_sender_id()
	players_ready[id] = is_ready
	player_ready_changed.emit(id, is_ready)
	if multiplayer.is_server() and all_players_ready():
		start_game.rpc()

@rpc("authority", "call_local", "reliable")
func sync_players(players_data):
	players_ready = players_data
	players_sync.emit(players_data)

func get_player_ready(peer_id):
	return players_ready.get(peer_id, false)

func all_players_ready():
	return players_ready.size() == MAX_PLAYERS and players_ready.values().all(func(x): return x)

@rpc("authority", "call_local", "reliable")
func start_game():
	game_started.emit()

@rpc("authority", "reliable")
func server_full():
	serverFull.emit()
