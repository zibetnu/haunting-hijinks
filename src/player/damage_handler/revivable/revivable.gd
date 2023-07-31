extends DamageHandler


@export var player: Player
@export var revived_state: State
@export var revive_time := 12
@export var revives_with: DamageSource.Type

var _can_progress := true
var _max_progress: int:
	get:
		return (revive_time
				* ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))

var _progress := 0:
	set(value):
		_progress = clampi(value, 0, _max_progress)


func _ready() -> void:
	player.died.connect(_on_player_died)


func _physics_process(_delta: float) -> void:
	_can_progress = true


func handle_damage(source: DamageSource, affected_player: Player) -> void:
	if not _can_progress:
		return

	if source.damage_type != revives_with:
		return

	_can_progress = false
	_progress += source.damage_amount
	if _progress < _max_progress:
		return

	_progress = 0
	if multiplayer.is_server():
		affected_player.health = affected_player.max_health
		affected_player.state_machine.transition_to.rpc(revived_state.name)
		player.revived.emit()


func _on_player_died() -> void:
	_progress = 0
