extends Control

signal host_requested
signal browse_requested
signal direct_join_requested

@onready var host_button: Button = $CenterContainer/VBoxContainer/HostButton
@onready var browse_button: Button = $CenterContainer/VBoxContainer/BrowseButton
@onready var direct_join_button: Button = $CenterContainer/VBoxContainer/DirectJoinButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	host_button.pressed.connect(func(): host_requested.emit())
	browse_button.pressed.connect(func(): browse_requested.emit())
	direct_join_button.pressed.connect(func(): direct_join_requested.emit())
	quit_button.pressed.connect(_on_quit_pressed)


func show_screen() -> void:
	visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()
