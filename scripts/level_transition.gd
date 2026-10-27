extends Area2D

## Cena que será carregada quando o Player tocar nesta área.
@export_file("*.tscn") var next_scene_path: String

var _transitioning := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node2D) -> void:
	if _transitioning:
		return
	if not body.is_in_group("player"):
		return
	if next_scene_path.is_empty():
		push_warning("level_transition: nenhuma cena foi definida no Inspetor.")
		return

	_transitioning = true
	SceneTransition.change_scene(next_scene_path)
