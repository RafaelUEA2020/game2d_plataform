extends CanvasLayer

## Duração (em segundos) de cada fade (escurecer e clarear).
@export var fade_time := 0.5

@onready var color_rect: ColorRect = $ColorRect
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const GAME_OVER_SCENE := "res://scenes/game_over.tscn"
var _busy := false


func _ready() -> void:
	# Garante que a transição funcione mesmo se o jogo estiver pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	color_rect.modulate.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func go_to_menu() -> void:
	change_scene(MAIN_MENU_SCENE, "", false)


func game_over() -> void:
	change_scene(GAME_OVER_SCENE, "", false)

func change_scene(scene_path: String, spawn_id: String = "", save_checkpoint: bool = true) -> void:
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

	# 3. Posiciona o Player e ajusta o HUD (com a tela ainda escura)
	_place_player(spawn_id)
	HUD.visible = not get_tree().current_scene.is_in_group("no_hud")

	# Checkpoint automático (menus e game over não salvam)
	if save_checkpoint:
		SaveManager.data["scene_path"] = scene_path
		SaveManager.data["spawn_id"] = spawn_id
		SaveManager.save_game()

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
			if player is CharacterBody2D:
				player.velocity = Vector2.ZERO
			_snap_camera()
			return

	push_warning("SceneTransition: spawn point '%s' não encontrado." % spawn_id)


func _snap_camera() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	# Atualiza a posição de destino da câmera e elimina o deslize
	camera.force_update_scroll()
	camera.reset_smoothing()	
