class_name LobbyConfig
extends Resource

@export_group("Capacity")
@export var max_players := 8
@export var join_in_progress := true

@export_group("Flow")
@export var use_lobby_screen := true
@export var require_ready_up := true
@export var require_approval := false

@export_group("Defaults")
@export var default_map := ""
@export var default_mode := ""


func build_settings() -> Dictionary:
	var settings := {max_players = max_players}
	if default_map != "":
		settings["map"] = default_map
	if default_mode != "":
		settings["mode"] = default_mode
	return settings
