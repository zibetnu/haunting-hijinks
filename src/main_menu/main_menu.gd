extends Control


const SECTION = "network"
const IP_KEY = "ip_address"
const PORT_KEY = "port"

@onready var connecting_dialog: AcceptDialog = $ConnectingDialog
@onready var notify_dialog: AcceptDialog = $NotifyDialog


func _ready() -> void:
	multiplayer.connected_to_server.connect(queue_free)
	multiplayer.connection_failed.connect(func(): _notify_user("Failed to connect."))
	_load_address()
	%JoinButton.grab_focus()


func cancel_connection_attempt() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func create_client(address: String, port: int) -> bool:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		_notify_user("Failed to create client.")
		return false

	multiplayer.multiplayer_peer = peer
	return true


func create_server(port: int) -> bool:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(port)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		_notify_user("Failed to create server.")
		return false

	multiplayer.multiplayer_peer = peer
	return true


func _load_address() -> void:
	var config := ConfigFile.new()
	if config.load(ProjectSettings.get_setting("global/settings_file_path")) != OK:
		return

	if not config.has_section(SECTION):
		return

	if config.has_section_key(SECTION, IP_KEY):
		%IPText.text = config.get_value(SECTION, IP_KEY)

	if config.has_section_key(SECTION, PORT_KEY):
		var port: int = config.get_value(SECTION, PORT_KEY)
		if port != 0:
			%PortText.text = str(port)


func _notify_user(message: String) -> void:
	notify_dialog.dialog_text = message
	notify_dialog.popup_centered()
	print(message)


func _save_address() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, IP_KEY, %IPText.text)
	config.set_value(SECTION, PORT_KEY, int(%PortText.text))
	config.save(ProjectSettings.get_setting("global/settings_file_path"))


func _on_host_button_pressed() -> void:
	if not create_server(int(%PortText.text)):
		return

	_save_address()
	multiplayer.peer_connected.emit(1)  # Set up server's player like any other.
	SceneChanger.change_scene_to_packed(SceneChanger.lobby)


func _on_join_button_pressed() -> void:
	if not create_client(%IPText.text, int(%PortText.text)):
		return

	_save_address()
	connecting_dialog.popup_centered()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
