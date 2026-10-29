extends Area2D

enum ItemType { COIN, KEY, GEM }

## Tipo do item. Define em qual contador ele soma.
@export var item_type: ItemType = ItemType.GEM
## Quanto soma no contador.
@export var amount: int = 1
## Se marcado, o item não reaparece depois de coletado (fica salvo).
@export var persistent: bool = true
## ID único no jogo inteiro. Se vazio, é gerado automaticamente.
@export var item_id: String = ""

var _id := ""
var _collected := false


func _ready() -> void:
	_id = item_id if item_id != "" else _auto_id()

	if persistent and SaveManager.is_collected(_id):
		queue_free()
		return

	body_entered.connect(_on_body_entered)


func _auto_id() -> String:
	# owner = cena (fase) onde este item foi colocado
	if owner:
		return "%s:%s" % [owner.scene_file_path, owner.get_path_to(self)]
	return str(get_path())


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true

	SaveManager.add_item(ItemType.keys()[item_type].to_lower(), amount)
	if persistent:
		SaveManager.mark_collected(_id)

	# Desliga a detecção e faz uma animação rápida antes de sumir
	set_deferred("monitoring", false)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 12.0, 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)
