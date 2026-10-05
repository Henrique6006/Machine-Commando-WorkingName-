extends StaticBody2D
## Inimigo simples: fica parado a distância e atira em linha reta (eixo
## dominante horizontal ou vertical) quando o jogador entra no raio de detecção.

@export var max_health: int = 3
@export var fire_rate: float = 1.5
@export var bullet_speed: float = 320.0
@export var enemy_bullet_scene: PackedScene = preload("res://scenes/EnemyBullet.tscn")

var health: int
var _target: Node2D = null
var _player_in_range: bool = false

@onready var detection_area: Area2D = $DetectionArea
@onready var shoot_timer: Timer = $ShootTimer
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
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
	var diff: Vector2 = _target.global_position - global_position
	var dir: Vector2
	# Estilo Commando: tiro travado no eixo dominante (horizontal ou vertical).
	if absf(diff.x) > absf(diff.y):
		dir = Vector2(signf(diff.x), 0)
	else:
		dir = Vector2(0, signf(diff.y))

	var bullet := enemy_bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.direction = dir
	bullet.speed = bullet_speed


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
