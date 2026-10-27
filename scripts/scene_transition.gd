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


func change_scene(scene_path: String) -> void:
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

	# 3. Fade in
	var tween_in := create_tween()
	tween_in.tween_property(color_rect, "modulate:a", 0.0, fade_time)
	await tween_in.finished

	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
