extends Control

signal leave_requested

const PLAYER_ROW := preload("res://scenes/ui/player_row.tscn")
const TEAMS: Array[String] = ["No team", "Red", "Blue"]
const MAPS: Array[String] = ["Harbour", "Reef", "Open Sea"]
const MODES: Array[String] = ["Deathmatch", "Capture", "Ranked"]

@onready var lobby_name_label: Label = $MarginContainer/VBoxContainer/HeaderBar/LobbyNameLabel
@onready var invite_button: Button = $MarginContainer/VBoxContainer/HeaderBar/InviteButton
@onready var leave_button: Button = $MarginContainer/VBoxContainer/HeaderBar/LeaveButton
@onready var players_header: Label = $MarginContainer/VBoxContainer/Body/PlayersPanel/MarginContainer/VBoxContainer/PlayersHeader
@onready var row_container: VBoxContainer = $MarginContainer/VBoxContainer/Body/PlayersPanel/MarginContainer/VBoxContainer/PlayerList/VBoxContainer
@onready var map_option: OptionButton = $MarginContainer/VBoxContainer/Body/SettingsPanel/MarginContainer/VBoxContainer/SettingsGrid/MapOption
@onready var mode_option: OptionButton = $MarginContainer/VBoxContainer/Body/SettingsPanel/MarginContainer/VBoxContainer/SettingsGrid/ModeOption
@onready var max_players_spin: SpinBox = $MarginContainer/VBoxContainer/Body/SettingsPanel/MarginContainer/VBoxContainer/SettingsGrid/MaxPlayersSpin
@onready var lobby_code_label: Label = $MarginContainer/VBoxContainer/FooterBar/LobbyCodeLabel
@onready var ready_button: CheckButton = $MarginContainer/VBoxContainer/FooterBar/ReadyButton
@onready var start_button: Button = $MarginContainer/VBoxContainer/FooterBar/StartButton

var _lobby: Node
var _players: Dictionary = {}
var _is_host := true


func _ready() -> void:
	_lobby = get_node_or_null("/root/Lobby")

	_populate_options()

	leave_button.pressed.connect(_on_leave_pressed)
	invite_button.pressed.connect(_on_invite_pressed)
	ready_button.toggled.connect(_on_ready_toggled)
	start_button.pressed.connect(_on_start_pressed)
	map_option.item_selected.connect(func(i): _set_setting("map", MAPS[i]))
	mode_option.item_selected.connect(func(i): _set_setting("mode", MODES[i]))
	max_players_spin.value_changed.connect(func(v): _set_setting("max_players", int(v)))
	
	var network := get_node_or_null("/root/Network")
	invite_button.visible = network != null and network.supports_invites()

	if _lobby:
		_lobby.player_joined.connect(_on_player_changed)
		_lobby.player_left.connect(_on_player_left)
		_lobby.player_updated.connect(_on_player_changed)
		_lobby.settings_changed.connect(_apply_settings)


func show_screen() -> void:
	visible = true
	_is_host = multiplayer.is_server()

	if _lobby:
		_players = _lobby.get_players()
		_apply_settings(_lobby.get_settings())
		lobby_name_label.text = _lobby.get_lobby_name()
		lobby_code_label.text = "Code: %s" % _lobby.get_join_code()
	else:
		_players = _fake_players()
		_apply_settings({map = "Harbour", mode = "Deathmatch", max_players = 8})
		lobby_name_label.text = "Blackwater Bay"
		lobby_code_label.text = "Code: TEST-01"

	_apply_role()
	_rebuild_players()


func _populate_options() -> void:
	for map in MAPS:
		map_option.add_item(map)
	for mode in MODES:
		mode_option.add_item(mode)
	max_players_spin.min_value = 2
	max_players_spin.max_value = 32


func _apply_role() -> void:
	map_option.disabled = not _is_host
	mode_option.disabled = not _is_host
	max_players_spin.editable = _is_host
	start_button.visible = _is_host
	ready_button.visible = not _is_host


func _apply_settings(settings: Dictionary) -> void:
	if settings.has("map"):
		map_option.select(MAPS.find(settings.map))
	if settings.has("mode"):
		mode_option.select(MODES.find(settings.mode))
	if settings.has("max_players"):
		max_players_spin.set_value_no_signal(settings.max_players)


func _rebuild_players() -> void:
	for child in row_container.get_children():
		child.queue_free()

	for peer_id in _players:
		var row := PLAYER_ROW.instantiate()
		row_container.add_child(row)
		row.setup(_players[peer_id], _is_host, TEAMS)
		row.kick_requested.connect(_on_kick_requested)
		row.team_changed.connect(_on_team_changed)

	players_header.text = "Players (%d/%d)" % [_players.size(), int(max_players_spin.value)]
	_update_start_button()


func _update_start_button() -> void:
	if not _is_host:
		return

	var everyone_ready := true
	for peer_id in _players:
		var info: Dictionary = _players[peer_id]
		if not info.get("is_host", false) and not info.get("ready", false):
			everyone_ready = false
			break

	start_button.disabled = _players.size() < 1 or not everyone_ready
	start_button.text = "Start" if everyone_ready else "Waiting…"


func _set_setting(key: String, value) -> void:
	if _lobby:
		_lobby.set_setting(key, value)
	if key == "max_players":
		_rebuild_players()


func _on_player_changed(peer_id: int, info: Dictionary) -> void:
	_players[peer_id] = info
	_rebuild_players()


func _on_player_left(peer_id: int) -> void:
	_players.erase(peer_id)
	_rebuild_players()


func _on_ready_toggled(pressed: bool) -> void:
	if _lobby:
		_lobby.set_ready(pressed)


func _on_team_changed(peer_id: int, team: int) -> void:
	if _lobby:
		_lobby.set_team(team)
	else:
		_players[peer_id]["team"] = team


func _on_kick_requested(peer_id: int) -> void:
	if _lobby:
		_lobby.kick(peer_id)


func _on_start_pressed() -> void:
	if _lobby:
		_lobby.start_match()


func _on_leave_pressed() -> void:
	if _lobby:
		_lobby.leave()
	leave_requested.emit()


func _on_invite_pressed() -> void:
	DisplayServer.clipboard_set(lobby_code_label.text.trim_prefix("Code: "))


func _fake_players() -> Dictionary:
	return {
		1: {peer_id = 1, name = "You", is_host = true, is_local = true, ready = true, team = 1},
		2: {peer_id = 2, name = "Redbeard", is_host = false, is_local = false, ready = true, team = 1},
		3: {peer_id = 3, name = "a player with a very long name", is_host = false, is_local = false, ready = false, team = 2},
		4: {peer_id = 4, name = "Squid", is_host = false, is_local = false, ready = false, team = 0},
	}
