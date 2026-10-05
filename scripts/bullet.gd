extends Area3D
## Projétil genérico usado tanto pelo jogador quanto pelos inimigos.
## target_group define quem este projétil pode atingir ("enemies" ou "player").

@export var speed: float = 14.0
@export var damage: int = 1
@export var lifetime: float = 2.5
@export var target_group: String = "enemies"

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
	if body.is_in_group(target_group) and body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
