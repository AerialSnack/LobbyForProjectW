extends Control

@onready var host_button = $HostButton
@onready var join_button = $JoinButton

func _ready():
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)

func _on_host_button_pressed():
	NetworkManager.host_game()
	var lobby = preload("res://scenes/Lobby.tscn").instantiate()
	get_tree().root.add_child(lobby)
	queue_free()

func _on_join_button_pressed():
	NetworkManager.join_game("127.0.0.1")  # Use localhost for testing
	var lobby = preload("res://scenes/Lobby.tscn").instantiate()
	get_tree().root.add_child(lobby)
	queue_free()
