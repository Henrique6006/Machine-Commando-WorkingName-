extends Area3D
## Míssil disparado pelo jogador. Ao atingir um inimigo (ou expirar), explode
## causando dano em área para todos os alvos dentro do raio de explosão.

@export var speed: float = 10.0
@export var lifetime: float = 3.0
@export var target_group: String = "enemies"
@export var explosion_radius: float = 3.0
@export var explosion_damage: int = 2

var direction: Vector3 = Vector3(0, 0, -1)


func _ready() -> void:
	if direction.length_squared() > 0.0001:
		look_at(global_position + direction, Vector3.UP)
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group):
		_explode()


func _explode() -> void:
	for body in get_tree().get_nodes_in_group(target_group):
		if is_instance_valid(body) and body.has_method("take_damage"):
			var dist: float = body.global_position.distance_to(global_position)
			if dist <= explosion_radius:
				body.take_damage(explosion_damage)
	queue_free()
