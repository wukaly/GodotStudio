extends Control

signal leave_requested

const PLAYER_ROW := preload("res://scenes/ui/player_row.tscn")
const REQUEST_ROW := preload("res://scenes/ui/join_request_row.tscn")
const TEAMS: Array[String] = ["No team", "Red", "Blue"]

@onready var requests_header: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RequestsHeader
@onready var request_list: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RequestList
@onready var players_header: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayersHeader
@onready var player_list: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayerList/VBoxContainer
@onready var resume_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var leave_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LeaveButton

var _lobby: Node
var _active := false


func _ready() -> void:
	_lobby = get_node_or_null("/root/Lobby")
	visible = false

	resume_button.pressed.connect(close)
	leave_button.pressed.connect(_on_leave_pressed)

	if _lobby:
		_lobby.player_joined.connect(func(_id, _info): _refresh())
		_lobby.player_left.connect(func(_id): _refresh())
		_lobby.player_updated.connect(func(_id, _info): _refresh())
		_lobby.join_requested.connect(func(_id, _name): _on_request_changed())
		_lobby.join_request_resolved.connect(func(_id): _on_request_changed())


func set_active(active: bool) -> void:
	_active = active
	if not active:
		close()


func open() -> void:
	visible = true
	_refresh()


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("ui_cancel"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func _on_request_changed() -> void:
	if _active and not visible:
		open()
	else:
		_refresh()


func _refresh() -> void:
	if not visible:
		return

	var is_host := multiplayer.is_server()

	for child in request_list.get_children():
		child.queue_free()
	for child in player_list.get_children():
		child.queue_free()

	var requests: Dictionary = _lobby.get_pending_requests() if _lobby else {}
	var show_requests := is_host and not requests.is_empty()
	requests_header.visible = show_requests
	request_list.visible = show_requests

	for peer_id in requests:
		var row := REQUEST_ROW.instantiate()
		request_list.add_child(row)
		row.setup(peer_id, requests[peer_id])
		row.accepted.connect(_on_accepted)
		row.denied.connect(_on_denied)

	var players: Dictionary = _lobby.get_players() if _lobby else {}
	for peer_id in players:
		var row := PLAYER_ROW.instantiate()
		player_list.add_child(row)
		row.setup(players[peer_id], is_host, TEAMS)
		row.kick_requested.connect(_on_kick_requested)

	players_header.text = "Players (%d)" % players.size()


func _on_accepted(peer_id: int) -> void:
	if _lobby:
		_lobby.approve(peer_id)

func _on_denied(peer_id: int) -> void:
	if _lobby:
		_lobby.deny(peer_id)

func _on_kick_requested(peer_id: int) -> void:
	if _lobby:
		_lobby.kick(peer_id)


func _on_leave_pressed() -> void:
	close()
	leave_requested.emit()
