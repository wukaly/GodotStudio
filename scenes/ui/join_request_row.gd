extends PanelContainer

signal accepted(peer_id: int)
signal denied(peer_id: int)

@onready var name_label: Label = $MarginContainer/HBoxContainer/NameLabel
@onready var accept_button: Button = $MarginContainer/HBoxContainer/AcceptButton
@onready var deny_button: Button = $MarginContainer/HBoxContainer/DenyButton

var peer_id: int


func _ready() -> void:
	accept_button.pressed.connect(func(): accepted.emit(peer_id))
	deny_button.pressed.connect(func(): denied.emit(peer_id))


func setup(request_peer_id: int, player_name: String) -> void:
	peer_id = request_peer_id
	name_label.text = "%s wants to join" % player_name
