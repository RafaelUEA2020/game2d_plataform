extends Camera2D

@export var player_group_name: String = "player"
@export_group("Limites da fase")

var player: Node2D


func _ready() -> void:
	var players := get_tree().get_nodes_in_group(player_group_name)
	if players.size() > 0:
		player = players[0] as Node2D
	else:
		push_error("Nenhum player encontrado no grupo '%s'!" % player_group_name)

func _physics_process(_delta: float) -> void:
	if not player:
		return
	global_position = player.global_position
