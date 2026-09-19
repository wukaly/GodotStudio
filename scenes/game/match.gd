extends Node3D

const PLAYER_SCENE := preload("res://scenes/game/player.tscn")

@onready var players: Node3D = $Players

var _ready_peers: Array[int] = []


func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		_ready_peers.append(1)
		_create_player(1, _spawn_point(0))
	else:
		_notify_scene_ready.rpc_id(1)


@rpc("any_peer", "reliable")
func _notify_scene_ready() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	if _ready_peers.has(peer_id):
		return

	for child in players.get_children():
		_create_player.rpc_id(peer_id, child.name.to_int(), child.global_position)

	_ready_peers.append(peer_id)

	var spawn := _spawn_point(players.get_child_count())
	for target in _ready_peers:
		if target != 1:
			_create_player.rpc_id(target, peer_id, spawn)
	_create_player(peer_id, spawn)


@rpc("authority", "reliable")
func _create_player(peer_id: int, spawn: Vector3) -> void:
	if players.has_node(str(peer_id)):
		return

	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	players.add_child(player, true)
	player.global_position = spawn


@rpc("authority", "reliable")
func _destroy_player(peer_id: int) -> void:
	var player := players.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()


func _on_peer_disconnected(peer_id: int) -> void:
	_ready_peers.erase(peer_id)
	_destroy_player.rpc(peer_id)
	_destroy_player(peer_id)


func _spawn_point(index: int) -> Vector3:
	var angle := TAU * index / 8.0
	return Vector3(cos(angle) * 5.0, 2.0, sin(angle) * 5.0)
