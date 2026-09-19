@tool
extends EditorPlugin

const AUTOLOAD_NAME := "Network"
const AUTOLOAD_PATH := "res://addons/godotstudio/network/network.gd"

func _enter_tree() -> void:
	if not ProjectSettings.has_setting("godot_studio/lobby/config"):
		ProjectSettings.set_setting("godot_studio/lobby/config", "res://config/lobby_config.tres")
		ProjectSettings.set_initial_value("godot_studio/lobby/config", "res://config/lobby_config.tres")
	add_autoload_singleton("Network", "res://addons/godotstudio/network/network.gd")
	add_autoload_singleton("Lobby", "res://addons/godotstudio/session/lobby.gd")

func _exit_tree() -> void:
	remove_autoload_singleton("Lobby")
	remove_autoload_singleton("Network")
