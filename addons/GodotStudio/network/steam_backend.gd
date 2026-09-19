class_name SteamBackend
extends MatchmakingBackend

const GAME_TAG := "GodotStudio"
const MAX_LOBBIES := 50

const RESULT_OK := 1
const LOBBY_TYPE_PUBLIC := 2
const LOBBY_COMPARISON_EQUAL := 0
const DISTANCE_WORLDWIDE := 3

const ENTER_SUCCESS := 1
const ENTER_DOESNT_EXIST := 2
const ENTER_NOT_ALLOWED := 3
const ENTER_FULL := 4
const ENTER_BANNED := 6

var lobby_id := 0

var _steam: Object
var _peer: MultiplayerPeer


static func is_available() -> bool:
	if not Engine.has_singleton("Steam"):
		return false

	var steam := Engine.get_singleton("Steam")
	var result = steam.steamInitEx()

	if typeof(result) == TYPE_DICTIONARY and result.get("status", 1) != 0:
		push_warning("Steam unavailable: %s" % result.get("verbal", "unknown"))
		return false

	return true


func _ready() -> void:
	_steam = Engine.get_singleton("Steam")

	_steam.connect("lobby_created", _on_lobby_created)
	_steam.connect("lobby_joined", _on_lobby_joined)
	_steam.connect("lobby_match_list", _on_lobby_match_list)
	_steam.connect("lobby_chat_update", _on_lobby_chat_update)
	_steam.connect("join_requested", _on_join_requested)

	multiplayer.peer_connected.connect(func(id): peer_joined.emit(id))
	multiplayer.peer_disconnected.connect(func(id): peer_left.emit(id))
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	_check_launch_arguments()


func _process(_delta: float) -> void:
	_steam.run_callbacks()


func host_lobby(config: Dictionary) -> void:
	leave()
	_steam.createLobby(LOBBY_TYPE_PUBLIC, int(config.get("max_players", 8)))


func join_lobby(target_lobby_id) -> void:
	leave()
	_steam.joinLobby(int(target_lobby_id))


func join_by_address(_address: String, _port: int) -> void:
	connection_failed.emit("Direct connection is not available over Steam")


func request_lobby_list(filters: Dictionary) -> void:
	_steam.addRequestLobbyListStringFilter("game", GAME_TAG, LOBBY_COMPARISON_EQUAL)
	_steam.addRequestLobbyListResultCountFilter(MAX_LOBBIES)
	_steam.addRequestLobbyListDistanceFilter(DISTANCE_WORLDWIDE)

	if filters.get("has_slots", false):
		_steam.addRequestLobbyListFilterSlotsAvailable(1)
	if filters.has("mode"):
		_steam.addRequestLobbyListStringFilter("mode", filters.mode, LOBBY_COMPARISON_EQUAL)

	_steam.requestLobbyList()


func leave() -> void:
	if lobby_id != 0:
		_steam.leaveLobby(lobby_id)
		lobby_id = 0

	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	_peer = null


func open_invite_panel() -> void:
	if lobby_id != 0:
		_steam.activateGameOverlayInviteDialog(lobby_id)


func set_joinable(joinable: bool) -> void:
	if lobby_id != 0 and _is_owner():
		_steam.setLobbyJoinable(lobby_id, joinable)


func supports_lobby_list() -> bool:
	return true


func supports_invites() -> bool:
	return true


func _on_lobby_created(result: int, new_lobby_id: int) -> void:
	if result != RESULT_OK:
		connection_failed.emit("Steam couldn't create the lobby (error %d)" % result)
		return

	lobby_id = new_lobby_id

	_steam.setLobbyData(lobby_id, "game", GAME_TAG)
	_steam.setLobbyData(lobby_id, "lobby_name", "%s's game" % _steam.getPersonaName())
	_steam.setLobbyData(lobby_id, "host_id", str(_steam.getSteamID()))
	_steam.setLobbyData(lobby_id, "in_progress", "0")
	_publish_member_count()

	_peer = ClassDB.instantiate("SteamMultiplayerPeer")
	var err: int = _peer.create_host(0)

	if err != OK:
		_peer = null
		connection_failed.emit("Couldn't open a Steam host socket (error %d)" % err)
		return

	multiplayer.multiplayer_peer = _peer
	lobby_joined.emit(lobby_id)


func _on_lobby_joined(joined_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != ENTER_SUCCESS:
		connection_failed.emit(_describe_join_failure(response))
		return

	lobby_id = joined_lobby_id

	if _is_owner():
		_publish_member_count()
		return

	var host_id := int(_steam.getLobbyData(lobby_id, "host_id"))
	if host_id == 0:
		host_id = _steam.getLobbyOwner(lobby_id)

	_peer = ClassDB.instantiate("SteamMultiplayerPeer")
	var err: int = _peer.create_client(host_id, 0)

	if err != OK:
		_peer = null
		connection_failed.emit("Couldn't reach the host over Steam (error %d)" % err)
		return

	multiplayer.multiplayer_peer = _peer
	lobby_joined.emit(lobby_id)


func _on_lobby_match_list(lobbies: Array) -> void:
	var results: Array[Dictionary] = []

	for found_id in lobbies:
		var members := int(_steam.getLobbyData(found_id, "members"))
		var capacity := int(_steam.getLobbyData(found_id, "max_players"))
		if capacity == 0:
			capacity = _steam.getLobbyMemberLimit(found_id)

		results.append({
			id = found_id,
			name = _steam.getLobbyData(found_id, "lobby_name"),
			mode = _steam.getLobbyData(found_id, "mode"),
			players = members,
			max_players = capacity,
			in_progress = _steam.getLobbyData(found_id, "in_progress") == "1",
		})

	lobby_list_updated.emit(results)


func _on_lobby_chat_update(changed_lobby_id: int, _changed_id: int, _maker_id: int, _state: int) -> void:
	if changed_lobby_id == lobby_id and _is_owner():
		_publish_member_count()


func _on_join_requested(requested_lobby_id: int, friend_id: int) -> void:
	print("Joining %s's lobby" % _steam.getFriendPersonaName(friend_id))
	join_lobby(requested_lobby_id)


func _on_server_disconnected() -> void:
	leave()
	disconnected.emit("The host closed the lobby")


func _check_launch_arguments() -> void:
	var args := OS.get_cmdline_args()
	for i in args.size() - 1:
		if args[i] == "+connect_lobby" and int(args[i + 1]) > 0:
			join_lobby(int(args[i + 1]))
			return


func _is_owner() -> bool:
	return lobby_id != 0 and _steam.getLobbyOwner(lobby_id) == _steam.getSteamID()


func _publish_member_count() -> void:
	_steam.setLobbyData(lobby_id, "members", str(_steam.getNumLobbyMembers(lobby_id)))
	_steam.setLobbyData(lobby_id, "max_players", str(_steam.getLobbyMemberLimit(lobby_id)))


func _describe_join_failure(response: int) -> String:
	match response:
		ENTER_DOESNT_EXIST:
			return "That lobby no longer exists"
		ENTER_FULL:
			return "That lobby is full"
		ENTER_NOT_ALLOWED:
			return "You don't have permission to join that lobby"
		ENTER_BANNED:
			return "You are banned from that lobby"
		_:
			return "Couldn't join that lobby (error %d)" % response
