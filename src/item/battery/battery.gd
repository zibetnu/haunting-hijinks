extends Item


@export var weak_to: DamageSource.Type


func _ready() -> void:
	$AnimationPlayer.play("spawn")
	await $AnimationPlayer.animation_finished
	$AnimationPlayer.play("bob")


@rpc("call_local")
func destoy() -> void:
	$AnimationPlayer.play("destroy")
	$CollisionShape2D.disabled = true
	await $AnimationPlayer.animation_finished
	if multiplayer.is_server():
		queue_free()


func take_damage(source: DamageSource) -> void:
	if source.damage_type != weak_to:
		return

	if multiplayer.is_server():
		destoy.rpc()


func _acquirer_allowed(acquirer: Variant) -> bool:
	if not "data" in acquirer:
		return false

	if not "battery_percentage" in acquirer.data:
		return false

	if acquirer.data.battery_percentage >= 0.9:
		return false

	return true


func _on_acquired(acquirer: Variant) -> void:
	acquirer.data.battery_percentage = 1
