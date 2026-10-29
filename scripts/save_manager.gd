extends Node

signal inventory_changed

const SAVE_PATH := "user://save.json"

var data := _default_data()


func _default_data() -> Dictionary:
	return {
		"scene_path": "",
		"spawn_id": "",
		"collected": [],
		"inventory": {},
	}


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: não foi possível salvar (erro %d)." % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		data.merge(parsed, true)
		inventory_changed.emit()
		return true
	push_warning("SaveManager: arquivo de save inválido.")
	return false


func new_game() -> void:
	data = _default_data()
	inventory_changed.emit()


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	new_game()


func continue_game() -> void:
	if not load_game() or data["scene_path"] == "":
		return
	SceneTransition.change_scene(data["scene_path"], data["spawn_id"])


func is_collected(id: String) -> bool:
	return id in data["collected"]


func mark_collected(id: String) -> void:
	if not is_collected(id):
		data["collected"].append(id)


func add_item(item_name: String, amount: int = 1) -> void:
	data["inventory"][item_name] = get_item_count(item_name) + amount
	inventory_changed.emit()


func get_item_count(item_name: String) -> int:
	# int() porque o JSON devolve números como float
	return int(data["inventory"].get(item_name, 0))


func spend_item(item_name: String, amount: int = 1) -> bool:
	if get_item_count(item_name) < amount:
		return false
	data["inventory"][item_name] = get_item_count(item_name) - amount
	inventory_changed.emit()
	return true


# Tecla de teste (só em builds de debug). Remova depois do menu principal.
func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		continue_game()
