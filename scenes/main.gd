extends Node

const MATCH_SCENE := preload("res://scenes/game/workspace.tscn")

@onready var world: Node3D = $World
@onready var ui: CanvasLayer = $UiRoot

var _current_match: Node3D


func _ready() -> void:
	var lobby := get_node_or_null("/root/Lobby")
	if lobby:
		lobby.match_starting.connect(_on_match_starting)

	var network := get_node_or_null("/root/Network")
	if network:
		network.disconnected.connect(func(_reason): end_match())


func _on_match_starting(_settings: Dictionary) -> void:
	end_match()
	_current_match = MATCH_SCENE.instantiate()
	world.add_child(_current_match)
	ui.visible = false


func end_match() -> void:
	if _current_match:
		_current_match.queue_free()
		_current_match = null
	ui.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if _current_match and event.is_action_pressed("ui_cancel"):
		var network := get_node_or_null("/root/Network")
		if network:
			network.leave()
		end_match()
