extends PanelContainer

signal kick_requested(peer_id)
signal team_changed(peer_id, team)

const COLOR_READY := Color(0.35, 0.8, 0.4)
const COLOR_NOT_READY := Color(0.4, 0.4, 0.45)

@onready var ready_indicator: ColorRect = $MarginContainer/HBoxContainer/ReadyIndicator
@onready var name_label: Label = $MarginContainer/HBoxContainer/NameLabel
@onready var host_badge: Label = $MarginContainer/HBoxContainer/HostBadge
@onready var team_option: OptionButton = $MarginContainer/HBoxContainer/TeamOption
@onready var kick_button: Button = $MarginContainer/HBoxContainer/KickButton

var peer_id: int
var _teams: Array[String] = []

func _ready() -> void:
	kick_button.pressed.connect(func(): kick_requested.emit(peer_id))
	team_option.item_selected.connect(func(i): team_changed.emit(peer_id, i))

func setup(info: Dictionary, local_is_host: bool, teams: Array[String]) -> void:
	peer_id = info.peer_id
	_teams = teams

	name_label.text = info.get("name", "Player %d" % peer_id)
	host_badge.visible = info.get("is_host", false)
	ready_indicator.color = COLOR_READY if info.get("ready", false) else COLOR_NOT_READY

	if team_option.item_count != teams.size():
		team_option.clear()
		for team in teams:
			team_option.add_item(team)
	team_option.select(info.get("team", 0))

	var is_local: bool = info.get("is_local", false)
	team_option.disabled = not is_local
	kick_button.visible = local_is_host and not is_local
