extends RigidBody3D
## Inimigo simples: fica parado a distância (congelado como corpo estático) e
## atira em linha reta (eixo dominante X ou Z) quando o jogador entra no raio
## de detecção.

@export var max_health: int = 3
@export var fire_rate: float = 1.5
@export var bullet_speed: float = 14.0
@export var enemy_bullet_scene: PackedScene = preload("res://enemy_bullet.tscn")

var health: int
var _target: Node3D = null
var _player_in_range: bool = false

@onready var detection_area: Area3D = $DetectionArea3D
@onready var shoot_timer: Timer = $ShootTimer
@onready var muzzle: Marker3D = $Muzzle


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	freeze = true
	shoot_timer.wait_time = fire_rate
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_target = body
		_player_in_range = true
		shoot_timer.start()


func _on_body_exited(body: Node) -> void:
	if body == _target:
		_player_in_range = false
		_target = null
		shoot_timer.stop()


func _on_shoot_timer_timeout() -> void:
	if _player_in_range and is_instance_valid(_target):
		_shoot_straight_line()


func _shoot_straight_line() -> void:
	var diff: Vector3 = _target.global_position - global_position
	var dir: Vector3
	# Estilo Commando: tiro travado no eixo dominante (X ou Z).
	if absf(diff.x) > absf(diff.z):
		dir = Vector3(signf(diff.x), 0, 0)
	else:
		dir = Vector3(0, 0, signf(diff.z))

	var bullet := enemy_bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.direction = dir
	bullet.speed = bullet_speed


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
