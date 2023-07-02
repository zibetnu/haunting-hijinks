extends Panel


@export var peer_id := 1:
	set(value):
		peer_id = value
		%IDLabel.text = str(value)
		%EditSynchronizer.set_multiplayer_authority(value)


func _ready() -> void:
	PeerData.peer_name_changed.connect(_on_peer_name_changed)
	%NameLineEdit.visible = multiplayer.get_unique_id() == peer_id
	%NameLabel.visible = not %NameLineEdit.visible
	get_peer_name()


func get_peer_name() -> void:
	var peer_name: String = PeerData.peer_names.get(peer_id, "")
	%NameLabel.text = peer_name
	if %NameLineEdit.text != peer_name:
		%NameLineEdit.text = peer_name


func set_peer_name(value: String) -> void:
	if PeerData.peer_names.get(peer_id, "") == value:
		return

	PeerData.set_peer_name(peer_id, value)


func _on_edit_synchronizer_synchronized() -> void:
	set_peer_name(%NameLineEdit.text)


func _on_name_line_edit_text_changed(new_text: String) -> void:
	set_peer_name(new_text)


func _on_peer_name_changed(id: int) -> void:
	if id != peer_id:
		return

	get_peer_name()
