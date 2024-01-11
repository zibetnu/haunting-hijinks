extends Node


@export var peer_id: PeerID:
	set(value):
		if peer_id:
			peer_id.changed.disconnect(_on_peer_id_changed)

		peer_id = value
		if peer_id:
			peer_id.changed.connect(_on_peer_id_changed)

@export var nodes: Array[Node]
@export var include_ghost_peer := false

var _original_process_modes := {}


func _ready() -> void:
	for node in nodes:
		_original_process_modes[node.get_path()] = node.process_mode


func _on_peer_id_changed(id: int) -> void:
	var local_id := multiplayer.get_unique_id()
	if local_id == id or (include_ghost_peer and local_id == PeerData.ghost_peer):
		for node in nodes:
			node.process_mode = _original_process_modes.get(
					node.get_path(), node.process_mode
			)

	else:
		for node in nodes:
			node.process_mode = Node.PROCESS_MODE_DISABLED
