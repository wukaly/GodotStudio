class_name MatchmakingBackend
extends Node

signal lobby_list_updated(lobbies: Array)
signal lobby_joined(lobby_id)
signal connection_failed(reason: String)
signal disconnected(reason: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)


func host_lobby(_config: Dictionary) -> void:
	push_error("host_lobby not implemented by %s" % get_script().resource_path)


func request_lobby_list(_filters: Dictionary) -> void:
	push_error("request_lobby_list not implemented by %s" % get_script().resource_path)


func join_lobby(_lobby_id) -> void:
	push_error("join_lobby not implemented by %s" % get_script().resource_path)


func join_by_address(_address: String, _port: int) -> void:
	push_error("join_by_address not implemented by %s" % get_script().resource_path)


func leave() -> void:
	push_error("leave not implemented by %s" % get_script().resource_path)

func supports_invites() -> bool:
	return false

func supports_lobby_list() -> bool:
	return false
