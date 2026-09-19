class_name EnetBackend
extends MatchmakingBackend

const DEFAULT_PORT := 7777
const MAX_CLIENTS := 32

var _peer: ENetMultiplayerPeer
var _pending_address := ""


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(func(id): peer_joined.emit(id))
	multiplayer.peer_disconnected.connect(func(id): peer_left.emit(id))


func host_lobby(config: Dictionary) -> void:
	leave()

	var port: int = config.get("port", DEFAULT_PORT)
	var max_players: int = config.get("max_players", MAX_CLIENTS)

	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port, max_players)

	if err != OK:
		_peer = null
		connection_failed.emit(_describe_host_error(err, port))
		return

	multiplayer.multiplayer_peer = _peer
	lobby_joined.emit("localhost:%d" % port)


func join_by_address(address: String, port: int) -> void:
	leave()

	_pending_address = "%s:%d" % [address, port]
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(address, port)

	if err != OK:
		_peer = null
		connection_failed.emit("Couldn't reach %s" % _pending_address)
		return

	multiplayer.multiplayer_peer = _peer


func join_lobby(lobby_id) -> void:
	if lobby_id is Dictionary and lobby_id.has("address"):
		join_by_address(lobby_id.address, lobby_id.get("port", DEFAULT_PORT))
	else:
		connection_failed.emit("This lobby can't be joined directly")


func request_lobby_list(_filters: Dictionary) -> void:
	lobby_list_updated.emit([])


func leave() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	_peer = null
	_pending_address = ""


func supports_lobby_list() -> bool:
	return false


func _on_connected_to_server() -> void:
	lobby_joined.emit(_pending_address)


func _on_connection_failed() -> void:
	var address := _pending_address
	leave()
	connection_failed.emit("No response from %s" % address)


func _on_server_disconnected() -> void:
	leave()
	disconnected.emit("The host closed the lobby")


func _describe_host_error(err: int, port: int) -> String:
	match err:
		ERR_ALREADY_IN_USE:
			return "Port %d is already in use" % port
		ERR_CANT_CREATE:
			return "Couldn't open port %d" % port
		_:
			return "Couldn't start the lobby (error %d)" % err
