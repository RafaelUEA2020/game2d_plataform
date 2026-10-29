extends Control

## Primeira fase do jogo (usada em "Novo Jogo").
@export_file("*.tscn") var first_scene_path: String
## Spawn point da primeira fase. Pode ficar vazio.
@export var first_spawn_id: String = ""

@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var quit_button: Button = $VBoxContainer/QuitButton


func _ready() -> void:
	add_to_group("no_hud")
	HUD.visible = false

	new_game_button.pressed.connect(_on_new_game)
	continue_button.pressed.connect(_on_continue)
	quit_button.pressed.connect(_on_quit)

	# Continuar só fica ativo se houver um save válido
	var has_valid_save := SaveManager.load_game() and SaveManager.data["scene_path"] != ""
	continue_button.disabled = not has_valid_save

	# Foco inicial (permite navegar com teclado e controle)
	if has_valid_save:
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()


func _on_new_game() -> void:
	if first_scene_path.is_empty():
		push_warning("MainMenu: defina a primeira fase no Inspetor.")
		return
	SaveManager.delete_save()
	SceneTransition.change_scene(first_scene_path, first_spawn_id)


func _on_continue() -> void:
	SaveManager.continue_game()


func _on_quit() -> void:
	get_tree().quit()
