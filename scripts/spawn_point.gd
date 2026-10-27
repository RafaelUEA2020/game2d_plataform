extends Marker2D

## Nome que identifica este ponto. Ex.: "porta_fase1", "entrada".
@export var spawn_id: String = ""


func _ready() -> void:
	add_to_group("spawn_points")
