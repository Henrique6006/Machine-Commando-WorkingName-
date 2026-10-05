extends Area2D
## Projétil genérico usado tanto pelo jogador quanto pelos inimigos.
## target_group define quem este projétil pode atingir ("enemies" ou "player").

@export var speed: float = 600.0
@export var damage: int = 1
@export var lifetime: float = 2.0
@export var target_group: String = "enemies"

var direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group) and body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
