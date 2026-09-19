extends Node

signal player_joined(peer_id: int, info: Dictionary)
signal player_left(peer_id: int)
signal player_updated(peer_id: int, info: Dictionary)
signal settings_changed(settings: Dictionary)
signal match_starting(settings: Dictionary)
signal kicked_from_lobby(reason: String)
signal join_requested(peer_id: int, player_name: String)
signal join_request_resolved(peer_id: int)

const CONFIG_SETTING := "godot_studio/lobby/config"
const DEFAULT_CONFIG_PATH := "res://lobby_config.tres"

var local_name := "Player"
var config: LobbyConfig

var _players: Dictionary = {}
var _settings: Dictionary = {}
var _pending: Dictionary = {}
var _lobby_name := ""
var _join_code := ""
var _in_progress := false


func _ready() -> void:
	config = _load_config()

	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_reset)
	multiplayer.connected_to_server.connect(_on_connected_to_server)

	var network := get_node_or_null("/root/Network")
	if network:
		network.lobby_joined.connect(_on_lobby_joined)


func get_players() -> Dictionary:
	return _players.duplicate(true)


func get_settings() -> Dictionary:
	return _settings.duplicate()


func get_lobby_name() -> String:
	return _lobby_name


func get_join_code() -> String:
	return _join_code


func is_in_progress() -> bool:
	return _in_progress


func get_pending_requests() -> Dictionary:
	return _pending.duplicate()


func set_ready(value: bool) -> void:
	_submit_update({ready = value})


func set_team(team: int) -> void:
	_submit_update({team = team})


func set_setting(key: String, value) -> void:
	if not multiplayer.is_server():
		return
	_settings[key] = value
	_receive_settings.rpc(_settings)
	_receive_settings(_settings)


func approve(peer_id: int) -> void:
	if not multiplayer.is_server() or not _pending.has(peer_id):
		return
	var player_name: String = _pending[peer_id]
	_pending.erase(peer_id)
	join_request_resolved.emit(peer_id)
	_admit(peer_id, player_name)


func deny(peer_id: int, reason := "The host declined your request") -> void:
	if not multiplayer.is_server() or not _pending.has(peer_id):
		return
	_pending.erase(peer_id)
	join_request_resolved.emit(peer_id)
	_reject(peer_id, reason)


func kick(peer_id: int, reason := "The host removed you from the lobby") -> void:
	if not multiplayer.is_server() or peer_id == 1:
		return
	_reject(peer_id, reason)


func start_match() -> void:
	if not multiplayer.is_server():
		return
	_in_progress = true
	_begin_match.rpc(_settings)
	_begin_match(_settings)


func leave() -> void:
	var network := get_node_or_null("/root/Network")
	if network:
		network.leave()
	_reset()


func _load_config() -> LobbyConfig:
	var path := DEFAULT_CONFIG_PATH
	if ProjectSettings.has_setting(CONFIG_SETTING):
		path = ProjectSettings.get_setting(CONFIG_SETTING)

	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is LobbyConfig:
			return loaded

	return LobbyConfig.new()


func _on_lobby_joined(lobby_id) -> void:
	if not multiplayer.is_server():
		return

	_settings = config.build_settings()
	_join_code = str(lobby_id)
	_lobby_name = "%s's game" % local_name
	_players = {1: _make_info(1, local_name, true)}
	_pending.clear()
	_in_progress = false

	player_joined.emit(1, _players[1])
	settings_changed.emit(_settings)

	if not config.use_lobby_screen:
		start_match()


func _on_connected_to_server() -> void:
	_register.rpc_id(1, local_name)


func _on_peer_disconnected(peer_id: int) -> void:
	_pending.erase(peer_id)
	if multiplayer.is_server() and _players.erase(peer_id):
		_remove_player.rpc(peer_id)
	_players.erase(peer_id)
	player_left.emit(peer_id)


@rpc("any_peer", "reliable")
func _register(player_name: String) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()

	if _in_progress and not config.join_in_progress:
		_reject(peer_id, "This game is already in progress")
		return

	if _players.size() + _pending.size() >= config.max_players:
		_reject(peer_id, "This game is full")
		return

	if config.require_approval:
		_pending[peer_id] = player_name
		_await_approval.rpc_id(peer_id)
		join_requested.emit(peer_id, player_name)
		return

	_admit(peer_id, player_name)


func _admit(peer_id: int, player_name: String) -> void:
	_players[peer_id] = _make_info(peer_id, player_name, false)

	_receive_settings.rpc_id(peer_id, _settings)
	_receive_lobby_info.rpc_id(peer_id, _lobby_name, _join_code)
	for existing_id in _players:
		_receive_player.rpc_id(peer_id, existing_id, _players[existing_id])

	_receive_player.rpc(peer_id, _players[peer_id])
	_receive_player(peer_id, _players[peer_id])

	if _in_progress:
		_begin_match.rpc_id(peer_id, _settings)


func _reject(peer_id: int, reason: String) -> void:
	_notify_rejected.rpc_id(peer_id, reason)
	await get_tree().create_timer(0.2).timeout
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)


func _submit_update(changes: Dictionary) -> void:
	if multiplayer.is_server():
		_apply_update(1, changes)
	else:
		_request_update.rpc_id(1, changes)


@rpc("any_peer", "reliable")
func _request_update(changes: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	_apply_update(multiplayer.get_remote_sender_id(), changes)


func _apply_update(peer_id: int, changes: Dictionary) -> void:
	if not _players.has(peer_id):
		return

	for key in ["ready", "team"]:
		if changes.has(key):
			_players[peer_id][key] = changes[key]

	_receive_player.rpc(peer_id, _players[peer_id])
	_receive_player(peer_id, _players[peer_id])


@rpc("authority", "reliable")
func _receive_player(peer_id: int, info: Dictionary) -> void:
	info = info.duplicate()
	info["is_local"] = peer_id == multiplayer.get_unique_id()

	var is_new := not _players.has(peer_id)
	_players[peer_id] = info

	if is_new:
		player_joined.emit(peer_id, info)
	else:
		player_updated.emit(peer_id, info)


@rpc("authority", "reliable")
func _remove_player(peer_id: int) -> void:
	_players.erase(peer_id)
	player_left.emit(peer_id)


@rpc("authority", "reliable")
func _receive_settings(settings: Dictionary) -> void:
	_settings = settings.duplicate()
	settings_changed.emit(_settings)


@rpc("authority", "reliable")
func _receive_lobby_info(lobby_name: String, join_code: String) -> void:
	_lobby_name = lobby_name
	_join_code = join_code


@rpc("authority", "reliable")
func _await_approval() -> void:
	pass


@rpc("authority", "reliable")
func _notify_rejected(reason: String) -> void:
	kicked_from_lobby.emit(reason)
	_reset()


@rpc("authority", "reliable")
func _begin_match(settings: Dictionary) -> void:
	_in_progress = true
	match_starting.emit(settings)


func _make_info(peer_id: int, player_name: String, is_host: bool) -> Dictionary:
	return {
		peer_id = peer_id,
		name = player_name,
		is_host = is_host,
		is_local = peer_id == multiplayer.get_unique_id(),
		ready = is_host or not config.require_ready_up,
		team = 0,
	}


func _reset() -> void:
	_players.clear()
	_settings.clear()
	_pending.clear()
	_lobby_name = ""
	_join_code = ""
	_in_progress = false
