extends Camera3D
## Faz a câmera acompanhar a posição do jogador sem nunca alterar seu ângulo.
## O deslocamento (offset) inicial entre câmera e jogador é mantido, então a
## câmera não gira quando o jogador vira para os lados.

@onready var player: Node3D = $"../Player"

var _offset: Vector3


func _ready() -> void:
	if player:
		_offset = global_position - player.global_position


func _process(_delta: float) -> void:
	if is_instance_valid(player):
		global_position = player.global_position + _offset
