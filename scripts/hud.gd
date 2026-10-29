extends CanvasLayer

@onready var gem_label: Label = $CoinLabel

func _ready() -> void:
	SaveManager.inventory_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	gem_label.text = "Moedas: %d" % SaveManager.get_item_count("gem")
