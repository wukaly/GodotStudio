extends Control

signal back_requested

@onready var address_field: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/AddressField
@onready var port_field: SpinBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PortField
@onready var cancel_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/CancelButton
@onready var connect_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/ConnectButton

var _network: Node
signal connecting_requested

func _ready() -> void:
	_network = get_node_or_null("/root/Network")
	cancel_button.pressed.connect(func(): back_requested.emit())
	connect_button.pressed.connect(_on_connect_pressed)
	address_field.text_submitted.connect(func(_t): _on_connect_pressed())


func show_screen() -> void:
	visible = true
	address_field.grab_focus()


func _on_connect_pressed() -> void:
	var address := address_field.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"
	connecting_requested.emit()
	if _network:
		_network.join_by_address(address, int(port_field.value))
	else:
		print("join: %s:%d" % [address, int(port_field.value)])
