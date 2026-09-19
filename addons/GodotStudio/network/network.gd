extends Node

signal lobby_list_updated(lobbies: Array)
signal lobby_joined(lobby_id)
signal connection_failed(reason: String)
signal disconnected(reason: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

var backend: MatchmakingBackend


func _ready() -> void:
	backend = _create_backend()
	backend.name = "Backend"
	add_child(backend)

	backend.lobby_list_updated.connect(func(l): lobby_list_updated.emit(l))
	backend.lobby_joined.connect(func(id): lobby_joined.emit(id))
	backend.connection_failed.connect(func(r): connection_failed.emit(r))
	backend.disconnected.connect(func(r): disconnected.emit(r))
	backend.peer_joined.connect(func(id): peer_joined.emit(id))
	backend.peer_left.connect(func(id): peer_left.emit(id))


func host_lobby(config: Dictionary = {}) -> void:
	backend.host_lobby(config)


func request_lobby_list(filters: Dictionary = {}) -> void:
	backend.request_lobby_list(filters)


func join_lobby(lobby_id) -> void:
	backend.join_lobby(lobby_id)


func join_by_address(address: String, port: int) -> void:
	backend.join_by_address(address, port)


func leave() -> void:
	backend.leave()


func is_connected_to_lobby() -> bool:
	return multiplayer.multiplayer_peer != null \
		and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func is_host() -> bool:
	return is_connected_to_lobby() and multiplayer.is_server()

func supports_invites() -> bool:
	return backend.supports_invites()

func supports_lobby_list() -> bool:
	return backend.supports_lobby_list()

func _create_backend() -> MatchmakingBackend:
	if SteamBackend.is_available():
		return SteamBackend.new()
	return EnetBackend.new()
