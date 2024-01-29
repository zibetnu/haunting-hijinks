extends Area2D


signal powering_failed

const CAST_LENGTHS: Array[int] = [0, 4, 5, 6, 7, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48]
const CAST_LONG_MAX_INDEX = 15
const CAST_LONG_MIN_INDEX = 5
const CAST_SHORT_MAX_INDEX = 4

@export var data: FlashlightData:
	set(value):
		if data and data.changed.is_connected(_on_data_changed):
			data.changed.disconnect(_on_data_changed)

		data = value
		if data and not data.changed.is_connected(_on_data_changed):
			data.changed.connect(_on_data_changed)

@export var powered: bool:
	get:
		return data.flashlight_powered

	set(value):
		data.flashlight_powered = value and data.battery > 0
		if value and data.battery == 0:
			powering_failed.emit()

@export var target_rotation: float:
	set(value):
		target_rotation = value


func _physics_process(delta: float) -> void:
	data.flashlight_rotation += clampf(
			angle_difference(data.flashlight_rotation, target_rotation),
			-data.flashlight_turn_speed * delta,
			data.flashlight_turn_speed * delta
	)

	powered = powered and data.battery > 0
	if not powered:
		return

	_update_cast_length()
	var all_colliders := []
	var all_colliders_and_points: Array[Dictionary] = []
	var all_repeat_raycasts := $RayCasts.get_children()
	for repeat_raycast in all_repeat_raycasts:
		var colliders_and_points = repeat_raycast.get_colliders_and_points()
		# Remove colliders that are past an object in the stop_flashlight group.
		for collider in colliders_and_points.colliders:
			if collider.is_in_group("stop_flashlight"):
				var resize_index: int = colliders_and_points.colliders.find(collider) + 1
				colliders_and_points.colliders.resize(resize_index)
				colliders_and_points.collision_points.resize(resize_index)
				break

		all_colliders += colliders_and_points.colliders
		all_colliders_and_points.append(colliders_and_points)

	var processed_colliders := []
	for collider in all_colliders:
		if collider in processed_colliders:
			continue

		processed_colliders.append(collider)
		if not collider.has_method("take_damage"):
			continue

		collider.take_damage(data.damage_deals)

	data.battery -= 1
	data.set_collision_points(_get_collision_points(all_colliders_and_points, all_repeat_raycasts))


func take_damage(source: DamageSource) -> void:
	if source.damage_type == data.damage_weak_to:
		data.battery = 0


func _get_collision_points(all_colliders_and_points: Array, raycasts: Array) -> Array[Vector2]:
	var rotated_collision_points: Array[Vector2] = []
	for i in range(mini(all_colliders_and_points.size(), raycasts.size())):
		rotated_collision_points.append(_get_rotated_collision_point(
				all_colliders_and_points[i], raycasts[i]
		))

	return rotated_collision_points


func _get_rotated_collision_point(colliders_and_points: Dictionary, raycast: RayCast2D) -> Vector2:
	if (
			colliders_and_points.collision_points.size() == 0
			# Assume that collider and point arrays have been resized to stop
			# at the first node that's in the stop_flashlight group.
			or not colliders_and_points.colliders[-1].is_in_group("stop_flashlight")
	):
		return (raycast.position
				+ Vector2(raycast.target_position.length(), 0).rotated(raycast.rotation)
		)

	var collision_point := raycast.to_local(colliders_and_points.collision_points[-1])
	return raycast.position + Vector2(collision_point.length(), 0).rotated(raycast.rotation)


func _update_cast_length() -> void:
	var index := 0
	var percentage := data.battery_percentage
	var low_perentage := data.battery_low_percentage
	if percentage < low_perentage:
		index = (ceil(CAST_SHORT_MAX_INDEX * (percentage / low_perentage)))

	else:
		index = (
				CAST_LONG_MIN_INDEX + ceil(
						(CAST_LONG_MAX_INDEX - CAST_LONG_MIN_INDEX)
						* ((percentage - low_perentage) / (1.0 - low_perentage))
				)
		)

	data.collision_cast_length = CAST_LENGTHS[index]


func _on_data_changed() -> void:
	rotation = data.flashlight_rotation
	for raycast: RayCast2D in $RayCasts.get_children():
		raycast.target_position.x = data.collision_cast_length
