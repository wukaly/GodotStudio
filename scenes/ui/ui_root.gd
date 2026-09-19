extends CanvasLayer

@onready var main_menu := $Screens/MainMenu
@onready var lobby_browser := $Screens/LobbyBrowser
@onready var direct_join := $Screens/DirectJoin
@onready var lobby := $Screens/Lobby
@onready var overlay := $ConnectionOverlay
@onready var pause_menu := $PauseMenu


func _ready() -> void:
	main_menu.host_requested.connect(_on_host_requested)
	main_menu.browse_requested.connect(func(): show_screen(lobby_browser))
	main_menu.direct_join_requested.connect(func(): show_screen(direct_join))
	lobby_browser.back_requested.connect(func(): show_screen(main_menu))
	direct_join.back_requested.connect(func(): show_screen(main_menu))
	lobby.leave_requested.connect(func(): show_screen(main_menu))

	overlay.dismissed.connect(func(): show_screen(main_menu))

	var network = get_node_or_null("/root/Network")
	if network:
		network.connection_failed.connect(_on_connection_failed)
		network.disconnected.connect(_on_disconnected)
		network.lobby_joined.connect(_on_lobby_joined)

	show_screen(main_menu)
	
	direct_join.connecting_requested.connect(
		func(): overlay.show_busy("Connecting…")
	)

func _on_lobby_joined(_id) -> void:
	overlay.hide_overlay()
	var lobby_service = get_node_or_null("/root/Lobby")
	if lobby_service and not lobby_service.config.use_lobby_screen:
		return
	show_screen(lobby)

func set_match_mode(active: bool) -> void:
	$Screens.visible = not active
	pause_menu.set_active(active)
	if not active:
		show_screen(main_menu)

func show_screen(screen: Control) -> void:
	for child in $Screens.get_children():
		child.visible = child == screen
	if screen.has_method("show_screen"):
		screen.show_screen()


func _on_host_requested() -> void:
	var network = get_node_or_null("/root/Network")
	if network:
		overlay.show_busy("Starting lobby…")
		network.host_lobby({})
	else:
		show_screen(lobby)


func _on_connection_failed(reason: String) -> void:
	overlay.show_error("Couldn't connect", reason)


func _on_disconnected(reason: String) -> void:
	overlay.show_error("Disconnected", reason)

	var lobby_service = get_node_or_null("/root/Lobby")
	if lobby_service:
		lobby_service.kicked_from_lobby.connect(_on_kicked)

func _on_kicked() -> void:
	overlay.show_error("Removed from lobby", "The host kicked you.")
