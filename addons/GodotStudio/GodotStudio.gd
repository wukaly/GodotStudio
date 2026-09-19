@tool
extends EditorPlugin

const AUTOLOAD_NAME := "Network"
const AUTOLOAD_PATH := "res://addons/GodotStudio/network/network.gd"


func _enter_tree() -> void:
	add_autoload_singleton("Network", "res://addons/GodotStudio/network/network.gd")
	add_autoload_singleton("Lobby", "res://addons/GodotStudio/session/lobby.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("Lobby")
	remove_autoload_singleton("Network")
