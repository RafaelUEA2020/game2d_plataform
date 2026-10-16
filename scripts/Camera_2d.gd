extends Camera2D

@export var player_group_name: String = "Player"
@export var tilemap_layers_parent_path: NodePath # Opcional: Nó pai onde ficam os TileMapLayers

var player: Node2D

func _ready() -> void:
	# 1. Encontra o player pelo grupo
	var players = get_tree().get_nodes_in_group(player_group_name)
	if players.size() > 0:
		player = players[0] as Node2D
	else:
		push_error("ERRO: Nenhum player encontrado no grupo '" + player_group_name + "'!")
		
	# 2. Configura os limites automaticamente com base nos TileMapLayers da cena
	setup_limits_from_tilemap_layers()

func setup_limits_from_tilemap_layers() -> void:
	var layers: Array[Node] = []
	
	# Se um nó pai foi especificado, procura os TileMapLayers dentro dele.
	# Caso contrário, varre a cena inteira procurando por nós TileMapLayer.
	if not tilemap_layers_parent_path.is_empty():
		var parent_node = get_node_or_null(tilemap_layers_parent_path)
		if parent_node:
			for child in parent_node.get_children():
				if child is TileMapLayer:
					layers.append(child)
	else:
		# Varre toda a árvore da cena atual buscando por TileMapLayers
		layers = get_tree().get_nodes_in_group("TileMapLayers") # Opcional, ou busca recursiva abaixo:
		layers = _find_all_tilemap_layers(get_tree().current_scene)

	if layers.is_empty():
		push_warning("Aviso: Nenhum TileMapLayer encontrado para calcular os limites da câmera.")
		return

	# Variáveis para encontrar os limites globais mínimos e máximos combinando todas as camadas
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	var found_valid_rect = false

	for layer in layers:
		if layer is TileMapLayer and layer.visible:
			var map_rect = layer.get_used_rect()
			if map_rect.has_area():
				found_valid_rect = true
				var tile_set = layer.tile_set
				if not tile_set:
					continue
				
				var tile_size = tile_set.tile_size
				
				# Converte as coordenadas do grid do tilemap para pixels globais considerando a escala e posição
				var local_left = (map_rect.position.x * tile_size.x) * layer.global_scale.x
				var local_top = (map_rect.position.y * tile_size.y) * layer.global_scale.y
				var local_right = ((map_rect.position.x + map_rect.size.x) * tile_size.x) * layer.global_scale.x
				var local_bottom = ((map_rect.position.y + map_rect.size.y) * tile_size.y) * layer.global_scale.y
				
				# Ajusta com a posição global do nó do TileMapLayer
				local_left += layer.global_position.x
				local_top += layer.global_position.y
				local_right += layer.global_position.x
				local_bottom += layer.global_position.y
				
				# Encontra os extremos gerais
				min_x = min(min_x, local_left)
				min_y = min(min_y, local_top)
				max_x = max(max_x, local_right)
				max_y = max(max_y, local_bottom)

	if found_valid_rect:
		limit_left = int(min_x)
		limit_top = int(min_y)
		limit_right = int(max_x)
		limit_bottom = int(max_y)
		print("Limites da câmera definidos com sucesso!")

# Função auxiliar para varrer recursivamente a cena atrás de TileMapLayers
func _find_all_tilemap_layers(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	if node is TileMapLayer:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_tilemap_layers(child))
	return result

func _physics_process(_delta: float) -> void:
	if not player:
		return
	
	global_position = player.global_position
