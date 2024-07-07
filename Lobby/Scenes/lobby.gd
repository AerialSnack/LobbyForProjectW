extends Control

@onready var player_list = $PlayerList
@onready var ready_button = $ReadyButton

var players = {}

func _ready():
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.player_ready_changed.connect(_on_player_ready_changed)
	NetworkManager.game_started.connect(_on_game_started)
	ready_button.pressed.connect(_on_ready_button_pressed)
	
	# Add local player
	var local_id = multiplayer.get_unique_id()
	_on_player_connected(local_id)
	
	# If we're not the server, request the current player states
	if not multiplayer.is_server():
		request_player_states.rpc_id(1)  # 1 is always the server's ID

func _on_player_connected(peer_id):
	players[peer_id] = {
	"name": "Player " + str(peer_id),
	"ready": false
	}
	update_player_list()
	
	# If we're the server and a new player joined, send them the current states
	if multiplayer.is_server() and peer_id != 1:
		var current_states = get_all_players_ready_status()
		sync_player_states.rpc_id(peer_id, current_states)

func _on_player_disconnected(peer_id):
	players.erase(peer_id)
	update_player_list()

func update_player_list():
	player_list.clear()
	for peer_id in players:
		var player = players[peer_id]
		var status = " (Ready)" if player["ready"] else " (Not Ready)"
		player_list.add_item(player["name"] + status)
	
	# Update local ready button
	var local_id = multiplayer.get_unique_id()
	if local_id in players:
		if players[local_id]["ready"]:
			ready_button.text = "Not Ready"
		else:
			ready_button.text = "Ready"

func _on_ready_button_pressed():
	var local_id = multiplayer.get_unique_id()
	var new_ready_state = !players[local_id]["ready"]
	NetworkManager.player_ready.rpc(new_ready_state)

func _on_player_ready_changed(peer_id, is_ready):
	if peer_id in players:
		players[peer_id]["ready"] = is_ready
	update_player_list()

func get_all_players_ready_status():
	var ready_status = {}
	for peer_id in players:
		ready_status[peer_id] = players[peer_id]["ready"]
	return ready_status

@rpc("any_peer")
func request_player_states():
	if multiplayer.is_server():
		var current_states = get_all_players_ready_status()
		sync_player_states.rpc_id(multiplayer.get_remote_sender_id(), current_states)

@rpc("authority")
func sync_player_states(states):
	for peer_id in states:
		if peer_id in players:
			players[peer_id]["ready"] = states[peer_id]
		else:
			players[peer_id] = {
			"name": "Player " + str(peer_id),
			"ready": states[peer_id]
			}
	update_player_list()  # Make sure to update the player list after syncing

func _on_game_started():
	var game_scene = preload("res://Scenes/game.tscn").instantiate()
	get_tree().root.add_child(game_scene)
	queue_free()
