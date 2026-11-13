extends RigidBody3D

@export var max_health: int = 3
@export var fire_rate: float = 1.5
@export var bullet_speed: float = 14.0
@export var enemy_bullet_scene: PackedScene = preload("res://enemy_bullet.tscn")
@export var weapon_pickup_scene: PackedScene = preload("res://weapon_pickup_ball.tscn")

## Comportamento de movimento: "stationary" (fica parado), "approach" (se aproxima
## até uma distância preferida, sem colar no jogador) ou "flee" (mantém distância,
## recuando quando o jogador se aproxima demais).
@export_enum("stationary", "approach", "flee") var movement_mode: String = "stationary"
@export var move_speed: float = 0.0
@export var preferred_distance: float = 5.0
@export var distance_deadzone: float = 1.0

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


func _physics_process(delta: float) -> void:
	if movement_mode == "stationary" or move_speed <= 0.0:
		return
	if not _player_in_range or not is_instance_valid(_target):
		return

	var to_target: Vector3 = _target.global_position - global_position
	to_target.y = 0.0
	var dist: float = to_target.length()
	if dist < 0.001:
		return
	var dir: Vector3 = to_target / dist

	var move_dir: Vector3 = Vector3.ZERO
	match movement_mode:
		"approach":
			if dist > preferred_distance + distance_deadzone:
				move_dir = dir
		"flee":
			if dist < preferred_distance - distance_deadzone:
				move_dir = -dir

	if move_dir != Vector3.ZERO:
		global_position += move_dir * move_speed * delta


func _on_shoot_timer_timeout() -> void:
	if _player_in_range and is_instance_valid(_target):
		_shoot_straight_line()


func _shoot_straight_line() -> void:
	var diff: Vector3 = _target.global_position - global_position
	var dir: Vector3
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
		_drop_weapon()
		queue_free()


func _drop_weapon() -> void:
	if weapon_pickup_scene == null:
		return
	var pickup := weapon_pickup_scene.instantiate()
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position
