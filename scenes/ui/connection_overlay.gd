extends Control

signal dismissed

@onready var status_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var message_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MessageLabel
@onready var dismiss_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/DismissButton

func _ready() -> void:
	dismiss_button.pressed.connect(_on_dismiss_pressed)
	visible = false

func show_busy(status: String, message := "") -> void:
	status_label.text = status
	message_label.text = message
	message_label.visible = message != ""
	dismiss_button.visible = false
	visible = true

func show_error(status: String, message := "", button_text := "Back to menu") -> void:
	status_label.text = status
	message_label.text = message
	message_label.visible = message != ""
	dismiss_button.text = button_text
	dismiss_button.visible = true
	visible = true

func hide_overlay() -> void:
	visible = false

func _on_dismiss_pressed() -> void:
	visible = false
	dismissed.emit()
