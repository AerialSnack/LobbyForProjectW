extends Control
@onready var host_button = $HostButton
@onready var join_button = $JoinButton
@onready var status_label = $StatusLabel  # Add this label to your Menu scene

func _ready():
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	NetworkManager.serverFull.connect(_on_server_full)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)

func _on_host_button_pressed():
	NetworkManager.host_game()
	load_lobby()

func _on_join_button_pressed():
	NetworkManager.join_game("127.0.0.1")
	status_label.text = "Connecting..."

func load_lobby():
	var lobby = preload("res://scenes/Lobby.tscn").instantiate()
	get_tree().root.add_child(lobby)
	queue_free()

func _on_server_full():
	status_label.text = "Server is full, cannot join"

func _on_connection_failed():
	status_label.text = "Failed to connect to server"

func _on_connection_succeeded():
	load_lobby()
