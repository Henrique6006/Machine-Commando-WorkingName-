extends CharacterBody2D
## Jogador: robô que se move em 8 direções e atira na direção que está virado.
## Placeholder de movimentação + tiro básico do Commando-like.

@export var speed: float = 220.0
@export var fire_rate: float = 0.25
@export var max_health: int = 5
@export var player_bullet_scene: PackedScene = preload("res://scenes/PlayerBullet.tscn")

var facing_dir: Vector2 = Vector2.RIGHT
var health: int
var _can_shoot: bool = true

@onready var visual: Node2D = $Visual
@onready var muzzle: Marker2D = $Visual/Muzzle
@onready var shoot_timer: Timer = $ShootTimer


func _ready() -> void:
	health = max_health
	add_to_group("player")
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)


func _physics_process(_delta: float) -> void:
	var input_dir := _get_input_direction()
	if input_dir != Vector2.ZERO:
		facing_dir = input_dir
	velocity = input_dir * speed
	move_and_slide()
	_update_visual()

	if _is_shoot_pressed() and _can_shoot:
		_shoot()


func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1
	return dir.normalized()


func _is_shoot_pressed() -> bool:
	return Input.is_physical_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


func _update_visual() -> void:
	visual.rotation = facing_dir.angle()


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
