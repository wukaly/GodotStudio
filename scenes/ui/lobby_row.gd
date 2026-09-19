extends PanelContainer

signal join_requested(lobby_id)

var lobby_id

func setup(data: Dictionary) -> void:
	lobby_id = data.id
	$MarginContainer/HBoxContainer/NameLabel.text = data.name
	$MarginContainer/HBoxContainer/ModeLabel.text = data.mode
	$MarginContainer/HBoxContainer/PlayersLabel.text = "%d/%d" % [data.players, data.max_players]
	$MarginContainer/HBoxContainer/StatusLabel.text = "In progress" if data.in_progress else "Waiting"
	$MarginContainer/HBoxContainer/JoinButton.disabled = data.players >= data.max_players

func _ready() -> void:
	$MarginContainer/HBoxContainer/JoinButton.pressed.connect(
		func(): join_requested.emit(lobby_id)
	)
