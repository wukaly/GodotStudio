extends Control

signal back_requested

const LOBBY_ROW := preload("res://scenes/ui/lobby_row.tscn")

@onready var refresh_button: Button = $MarginContainer/VBoxContainer/HeaderBar/RefreshButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/HeaderBar/BackButton
@onready var search_field: LineEdit = $MarginContainer/VBoxContainer/FilterBar/SearchField
@onready var mode_filter: OptionButton = $MarginContainer/VBoxContainer/FilterBar/ModeFilter
@onready var hide_full_check: CheckBox = $MarginContainer/VBoxContainer/FilterBar/HideFullCheck
@onready var lobby_list: ScrollContainer = $MarginContainer/VBoxContainer/Results/MarginContainer/LobbyList
@onready var row_container: VBoxContainer = $MarginContainer/VBoxContainer/Results/MarginContainer/LobbyList/VBoxContainer
@onready var empty_label: Label = $MarginContainer/VBoxContainer/Results/MarginContainer/EmptyLabel
@onready var searching_label: Label = $MarginContainer/VBoxContainer/Results/MarginContainer/SearchingLabel

var _lobbies: Array[Dictionary] = []
var _network: Node


func _ready() -> void:
	_network = get_node_or_null("/root/Network")

	refresh_button.pressed.connect(refresh)
	back_button.pressed.connect(func(): back_requested.emit())
	search_field.text_changed.connect(func(_t): _rebuild())
	mode_filter.item_selected.connect(func(_i): _rebuild())
	hide_full_check.toggled.connect(func(_p): _rebuild())

	if _network:
		_network.lobby_list_updated.connect(_on_lobby_list_updated)

	if mode_filter.item_count == 0:
		mode_filter.add_item("All modes")

	_show_state(searching_label)


func show_screen() -> void:
	visible = true
	refresh()


func refresh() -> void:
	_show_state(searching_label)
	refresh_button.disabled = true

	if _network:
		_network.request_lobby_list(_build_filters())
	else:
		await get_tree().create_timer(0.4).timeout
		_on_lobby_list_updated(_fake_lobbies())


func _on_lobby_list_updated(lobbies: Array) -> void:
	_lobbies.assign(lobbies)
	refresh_button.disabled = false
	_rebuild()


func _rebuild() -> void:
	for child in row_container.get_children():
		child.queue_free()

	var visible_lobbies := _lobbies.filter(_passes_filters)

	if visible_lobbies.is_empty():
		empty_label.text = "No lobbies found" if _lobbies.is_empty() else "No lobbies match your filters"
		_show_state(empty_label)
		return

	_show_state(lobby_list)

	for lobby in visible_lobbies:
		var row := LOBBY_ROW.instantiate()
		row_container.add_child(row)
		row.setup(lobby)
		row.join_requested.connect(_on_join_requested)


func _passes_filters(lobby: Dictionary) -> bool:
	var query := search_field.text.strip_edges().to_lower()
	if query != "" and not lobby.name.to_lower().contains(query):
		return false

	if mode_filter.selected > 0 and lobby.mode != mode_filter.get_item_text(mode_filter.selected):
		return false

	if hide_full_check.button_pressed and lobby.players >= lobby.max_players:
		return false

	return true


func _build_filters() -> Dictionary:
	var filters := {}
	if mode_filter.selected > 0:
		filters["mode"] = mode_filter.get_item_text(mode_filter.selected)
	if hide_full_check.button_pressed:
		filters["has_slots"] = true
	return filters


func _on_join_requested(lobby_id) -> void:
	if _network:
		_network.join_lobby(lobby_id)
	else:
		print("join requested: ", lobby_id)


func _show_state(node: Control) -> void:
	lobby_list.visible = node == lobby_list
	empty_label.visible = node == empty_label
	searching_label.visible = node == searching_label


func _fake_lobbies() -> Array[Dictionary]:
	return [
		{id = 1, name = "Blackwater Bay", mode = "Deathmatch", players = 3, max_players = 8, in_progress = false},
		{id = 2, name = "A very long lobby name that should be trimmed", mode = "Capture", players = 8, max_players = 8, in_progress = false},
		{id = 3, name = "casuals only", mode = "Deathmatch", players = 5, max_players = 12, in_progress = true},
		{id = 4, name = "ranked 3v3", mode = "Ranked", players = 1, max_players = 6, in_progress = false},
		{id = 5, name = "test lobby", mode = "Capture", players = 0, max_players = 4, in_progress = false},
	]
