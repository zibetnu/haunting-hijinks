extends Node2D


const Battery = preload("res://src/item/battery/battery.tscn")
const MAX_BATTERY_SPAWN_ATTEMPTS = 100

@export var spawn_area_top_left: Node2D
@export var spawn_area_bottom_right: Node2D
@export var spawn_root : Node2D

var _batteries_spawned := 0
var _exception_count := 0

@onready var _position_checker := $PositionChecker


func _ready() -> void:
	_add_exceptions()


func _add_exceptions() -> void:
	if _exception_count >= get_tree().get_nodes_in_group("aura_areas").size():
		return

	_exception_count = 0
	_position_checker.clear_exceptions()
	get_tree().get_nodes_in_group("aura_areas").map(
			func(aura_area):
					_position_checker.add_exception(aura_area)
					_exception_count += 1
	)


func _get_random_battery_position() -> Vector2:
	return Vector2(
			randf_range(spawn_area_top_left.position.x, spawn_area_bottom_right.position.x),
			randf_range(spawn_area_top_left.position.y, spawn_area_bottom_right.position.y)
	)


func _is_position_clear(check_position: Vector2) -> bool:
	_add_exceptions()
	_position_checker.position = check_position
	_position_checker.force_shapecast_update()
	return not _position_checker.is_colliding()


func _on_timer_timeout() -> void:
	if not multiplayer.is_server():
		return

	var batteries_needed = 0
	for flashlight in get_tree().get_nodes_in_group("flashlights"):
		if not flashlight.is_battery_low:
			continue

		if flashlight.player.health == 0:
			continue

		batteries_needed += 1

	if _batteries_spawned >= batteries_needed:
		return

	var instance = Battery.instantiate()
	var instance_position := _get_random_battery_position()
	var i := 0
	while i < MAX_BATTERY_SPAWN_ATTEMPTS and not _is_position_clear(instance_position):
		instance_position = _get_random_battery_position()
		i += 1

	if not (i < MAX_BATTERY_SPAWN_ATTEMPTS):
		push_error("Could not find valid battery spawn point.")
		instance.queue_free()
		return

	instance.position = instance_position
	instance.tree_exited.connect(_on_battery_tree_exited)
	spawn_root.add_child(instance, true)
	_batteries_spawned += 1


func _on_battery_tree_exited() -> void:
	_batteries_spawned -= 1
