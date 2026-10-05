extends CharacterBody3D
## Jogador: robô que se move em um plano top-down (XZ) e atira na direção
## que está virado. Placeholder de movimentação + tiro básico do Commando-like.

@export var speed: float = 6.0
@export var fire_rate: float = 0.25
@export var max_health: int = 5
@export var gravity: float = 20.0
@export var player_bullet_scene: PackedScene = preload("res://player_bullet.tscn")

var facing_dir: Vector3 = Vector3(0, 0, -1)
var health: int
var _can_shoot: bool = true

@onready var muzzle: Marker3D = $Muzzle
@onready var shoot_timer: Timer = $ShootTimer


func _ready() -> void:
	health = max_health
	add_to_group("player")
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)


func _physics_process(delta: float) -> void:
	var input_dir := _get_input_direction()
	if input_dir != Vector3.ZERO:
		facing_dir = input_dir
		look_at(global_position + facing_dir, Vector3.UP)

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


func _shoot() -> void:
	_can_shoot = false
	shoot_timer.start(fire_rate)

	var bullet := player_bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.direction = facing_dir


func _on_shoot_timer_timeout() -> void:
	_can_shoot = true


func take_damage(amount: int) -> void:
	health -= amount
	print("Player health: %d" % health)
	if health <= 0:
		print("Player destruído!")
		queue_free()
