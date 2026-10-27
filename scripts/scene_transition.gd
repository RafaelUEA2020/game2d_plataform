extends CanvasLayer

## Duração (em segundos) de cada fade (escurecer e clarear).
@export var fade_time := 0.5

@onready var color_rect: ColorRect = $ColorRect

var _busy := false


func _ready() -> void:
	# Garante que a transição funcione mesmo se o jogo estiver pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	color_rect.modulate.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func change_scene(scene_path: String, spawn_id: String = "") -> void:
	if _busy:
		return
	_busy = true

	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	# 1. Fade out
	var tween_out := create_tween()
	tween_out.tween_property(color_rect, "modulate:a", 1.0, fade_time)
	await tween_out.finished

	# 2. Troca a cena
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame

	# 3. Move o Player para o spawn point (com a tela ainda escura)
	_place_player(spawn_id)

	# 4. Fade in
	var tween_in := create_tween()
	tween_in.tween_property(color_rect, "modulate:a", 0.0, fade_time)
	await tween_in.finished

	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func _place_player(spawn_id: String) -> void:
	if spawn_id.is_empty():
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		push_warning("SceneTransition: Player não encontrado na nova cena.")
		return

	for spawn in get_tree().get_nodes_in_group("spawn_points"):
		if spawn.spawn_id == spawn_id:
			player.global_position = spawn.global_position
			# Zera a velocidade para o Player não "herdar" movimento da fase anterior
			if player is CharacterBody2D:
				player.velocity = Vector2.ZERO
			return

	push_warning("SceneTransition: spawn point '%s' não encontrado." % spawn_id)
