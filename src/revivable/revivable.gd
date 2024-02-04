extends Node


signal revived

@export var enabled := true:
	set(value):
		enabled = value
		set_physics_process(enabled)
		if not enabled:
			_can_progress = false
			progress = 0

@export var revive_time := 12
@export var revives_with: DamageSource.Type

var max_progress: int:
	get:
		return (revive_time
				* ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))

var progress := 0:
	set(value):
		progress = clampi(value, 0, max_progress)
		if progress >= max_progress:
			progress = 0
			revived.emit()

var _can_progress := true


func _physics_process(_delta: float) -> void:
	_can_progress = true


func disable() -> void:
	enabled = false


func enable() -> void:
	enabled = true


func take_damage(source: DamageSource) -> void:
	if not _can_progress:
		return

	if source.damage_type != revives_with:
		return

	_can_progress = false
	progress += source.damage_amount
