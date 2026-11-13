extends Area3D
## Arma dropada por um inimigo ao morrer.
## Quando o jogador passa por cima, o item é coletado (destruído) e o tiro dele é melhorado.
## upgrade_type define qual melhoria é concedida: "rapid_fire", "triple_shot" ou "missile".

@export var upgrade_type: String = "rapid_fire"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("collect_weapon_upgrade"):
		body.collect_weapon_upgrade(upgrade_type)
		queue_free()
