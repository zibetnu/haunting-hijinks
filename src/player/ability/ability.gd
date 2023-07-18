class_name Ability
extends Node2D


@export var player: Player = null
@export var states: Array[State] = []

# _state_names is used in classes that extend Ability.
@warning_ignore("unused_private_class_variable")
@onready var _state_names := states.map(func(state): return state.name)


func _ready() -> void:
	player.state_machine.transitioned.connect(_on_player_state_machine_transitioned)
	set_process(false)
	set_process_input(false)
	set_physics_process(false)
	set_process_unhandled_input(false)


func _on_player_state_machine_transitioned(_state_name: String) -> void:
	pass
