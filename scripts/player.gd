extends CharacterBody3D

@export var speed: float = 6.0
@export var fire_rate: float = 0.25
@export var max_health: int = 5
@export var gravity: float = 20.0
@export var player_bullet_scene: PackedScene = preload("res://player_bullet.tscn")
@export var missile_bullet_scene: PackedScene = preload("res://missile_bullet.tscn")
@export var fire_rate_decrease_per_upgrade: float = 0.03
@export var min_fire_rate: float = 0.05
@export var bullet_damage_increase_per_upgrade: int = 1
@export var side_shot_spread_degrees: float = 15.0
@export var missile_damage: int = 2
@export var missile_explosion_radius: float = 3.0
## Quantos tiros cada arma coletada dura antes de expirar. Pegar a mesma arma
## de novo reabastece o limite (e também soma o bônus, como antes).
@export var shots_per_weapon: int = 20

## Velocidade do dash (em unidades/seg) enquanto ele está ativo.
@export var dash_speed: float = 18.0
## Duração do dash, em segundos.
@export var dash_duration: float = 0.15
## Tempo de recarga antes de poder usar o dash novamente.
@export var dash_cooldown: float = 0.6

var facing_dir: Vector3 = Vector3(0, 0, -1)
var health: int
var _can_shoot: bool = true
var base_fire_rate: float
var bullet_damage: int = 1
## Nível acumulado do upgrade de cadência/dano (drop "bola"/rapid_fire).
var rapid_fire_level: int = 0
## Quantidade de pares de tiros extras (drop "quadrado"/triple_shot). Cada par soma
## 2 tiros angulados além do tiro central normal.
var side_shot_pairs: int = 0
## Quantidade de mísseis disparados junto com o tiro normal (drop "cilindro"/missile).
var missile_count: int = 0

## Tiros restantes de cada arma coletada antes dela expirar e o bônus ser perdido.
var _shots_remaining: Dictionary = {
	"rapid_fire": 0,
	"triple_shot": 0,
	"missile": 0,
}

## Estado do dash: se está ativo, se pode ser disparado de novo e para onde ele empurra o jogador.
var _is_dashing: bool = false
var _can_dash: bool = true
var _dash_dir: Vector3 = Vector3.ZERO
var _was_dash_pressed: bool = false

@onready var muzzle: Marker3D = $Muzzle
@onready var shoot_timer: Timer = $ShootTimer
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer


func _ready() -> void:
	health = max_health
	base_fire_rate = fire_rate
	add_to_group("player")
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	dash_timer.one_shot = true
	dash_timer.wait_time = dash_duration
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.wait_time = dash_cooldown
	dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timer_timeout)


func _physics_process(delta: float) -> void:
	var input_dir := _get_input_direction()
	if input_dir != Vector3.ZERO:
		facing_dir = input_dir
		look_at(global_position + facing_dir, Vector3.UP)

	var dash_pressed := _is_dash_pressed()
	if dash_pressed and not _was_dash_pressed and _can_dash and not _is_dashing:
		_start_dash()
	_was_dash_pressed = dash_pressed

	if _is_dashing:
		velocity.x = _dash_dir.x * dash_speed
		velocity.z = _dash_dir.z * dash_speed
	else:
		velocity.x = input_dir.x * speed
		velocity.z = input_dir.z * speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	if _is_shoot_pressed() and _can_shoot:
		_shoot()


func _get_input_direction() -> Vector3:
	var dir := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.z -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.z += 1
	return dir.normalized()


func _is_shoot_pressed() -> bool:
	return Input.is_physical_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


func _is_dash_pressed() -> bool:
	return Input.is_physical_key_pressed(KEY_SHIFT)


func _start_dash() -> void:
	_is_dashing = true
	_can_dash = false
	_dash_dir = facing_dir
	dash_timer.start()
	dash_cooldown_timer.start()


func _on_dash_timer_timeout() -> void:
	_is_dashing = false


func _on_dash_cooldown_timer_timeout() -> void:
	_can_dash = true


func _shoot() -> void:
	_can_shoot = false
	shoot_timer.start(fire_rate)

	_fire_bullet(facing_dir)
	for i in range(side_shot_pairs):
		var spread_angle: float = deg_to_rad(side_shot_spread_degrees * float(i + 1))
		_fire_bullet(facing_dir.rotated(Vector3.UP, spread_angle))
		_fire_bullet(facing_dir.rotated(Vector3.UP, -spread_angle))
	for i in range(missile_count):
		_fire_missile(facing_dir)

	if rapid_fire_level > 0:
		_consume_shot("rapid_fire")
	if side_shot_pairs > 0:
		_consume_shot("triple_shot")
	if missile_count > 0:
		_consume_shot("missile")


func _fire_bullet(dir: Vector3) -> void:
	var bullet := player_bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.direction = dir
	bullet.damage = bullet_damage


func _fire_missile(dir: Vector3) -> void:
	var missile := missile_bullet_scene.instantiate()
	get_tree().current_scene.add_child(missile)
	missile.global_position = muzzle.global_position
	missile.direction = dir
	missile.explosion_damage = missile_damage
	missile.explosion_radius = missile_explosion_radius


func _on_shoot_timer_timeout() -> void:
	_can_shoot = true


func collect_weapon_upgrade(upgrade_type: String) -> void:
	match upgrade_type:
		"rapid_fire":
			rapid_fire_level += 1
			_recalculate_rapid_fire()
			print("Cadência/dano melhorados! Dano %d, cadência %.2f" % [bullet_damage, fire_rate])
		"triple_shot":
			side_shot_pairs += 1
			print("Tiro triplo melhorado! Pares extras: %d" % side_shot_pairs)
		"missile":
			missile_count += 1
			print("Mísseis adicionados! Total: %d" % missile_count)
		_:
			push_warning("Tipo de upgrade desconhecido: %s" % upgrade_type)
			return
	_shots_remaining[upgrade_type] = shots_per_weapon


func _recalculate_rapid_fire() -> void:
	bullet_damage = 1 + rapid_fire_level * bullet_damage_increase_per_upgrade
	fire_rate = maxf(min_fire_rate, base_fire_rate - rapid_fire_level * fire_rate_decrease_per_upgrade)


func _consume_shot(upgrade_type: String) -> void:
	_shots_remaining[upgrade_type] -= 1
	if _shots_remaining[upgrade_type] <= 0:
		_expire_weapon(upgrade_type)


func _expire_weapon(upgrade_type: String) -> void:
	match upgrade_type:
		"rapid_fire":
			rapid_fire_level = 0
			_recalculate_rapid_fire()
		"triple_shot":
			side_shot_pairs = 0
		"missile":
			missile_count = 0
	_shots_remaining[upgrade_type] = 0
	print("Arma expirou: %s" % upgrade_type)


func take_damage(amount: int) -> void:
	health -= amount
	print("Player health: %d" % health)
	if health <= 0:
		print("Player destruído!")
		queue_free()
