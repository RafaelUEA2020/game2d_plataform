extends CharacterBody2D

@export var base_speed: float = 202.0
@export var air_speed: float = 185.0
const JUMP_VELOCITY = -350.0

# --- CONFIGURAÇÕES DO DASH ---
@export_category("Configurações de Dash")
@export var dash_distance: float = 150.0     # Distância total que o dash percorre em pixels
@export var dash_duration: float = 0.2       # Tempo que o dash dura em segundos
@export var dash_cooldown: float = 2.0     # Tempo de recarga em segundos

# Máscara de colisão: Escolha quais camadas ignorar durante o dash (Bitmask)
# Dica: No editor, você pode somar os valores ou usar ferramentas de exportação de layers, 
# mas por padrão configurar o collision_mask diretamente via código resolve.
@export_flags_2d_physics var layers_to_ignore_during_dash: int = 0 

var speed: float = 202.0
var is_dashing: bool = false
var can_dash: bool = true
var dash_timer: float = 0.0
var cooldown_timer: float = 0.0
var dash_dir: float = 1.0
var original_collision_mask: int = 0

func _ready() -> void:
	speed = base_speed
	original_collision_mask = collision_mask

func _physics_process(delta: float) -> void:
	# Gerencia o cooldown do dash
	if not can_dash:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			can_dash = true
			print("Dash recarregado! Pronto para uso.")

	# Se estiver executando o dash, ele trava a movimentação normal e move rápido
	if is_dashing:
		dash_timer -= delta
		# Velocidade baseada na distância dividida pelo tempo para garantir a precisão do trajeto
		velocity.x = dash_dir * (dash_distance / dash_duration)
		velocity.y = 0 # Anula a gravidade durante o dash horizontal
		move_and_slide()
		
		if dash_timer <= 0.0:
			end_dash()
		return

	# Acionar o Dash (ex: tecla "dash" configurada no Input Map)
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash()

	# Adiciona a gravidade padrão
	if not is_on_floor():
		velocity += get_gravity() * delta
		speed = air_speed
	else:
		speed = base_speed

	# Lógica de Pulo
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movimentação Horizontal
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * speed
		dash_dir = direction # Guarda a última direção que o player olhou/andou
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

func start_dash() -> void:
	is_dashing = true
	can_dash = false
	dash_timer = dash_duration
	cooldown_timer = dash_cooldown
	
	# Aplica a invencibilidade ignorando a camada escolhida no Inspector
	if layers_to_ignore_during_dash != 0:
		collision_mask = collision_mask & ~layers_to_ignore_during_dash
	
	print("Dash iniciado! Recarga de 2 segundos iniciada...")

func end_dash() -> void:
	is_dashing = false
	# Restaura a máscara de colisão original ao fim do dash
	collision_mask = original_collision_mask
