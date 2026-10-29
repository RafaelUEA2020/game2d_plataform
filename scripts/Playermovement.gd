extends CharacterBody2D

@export var base_speed: float = 202.0
@export var air_speed: float = 185.0
const JUMP_VELOCITY = -350.0
const DOUBLE_JUMP_MULTIPLIER = 0.70  # força do pulo no ar = 65% do pulo normal
const MAX_AIR_JUMPS = 1              # pulos extras permitidos no ar antes de tocar o chão

# --- CONFIGURAÇÕES DO DASH ---
@export_category("Configurações de Dash")
@export var dash_distance: float = 150.0     
@export var dash_duration: float = 0.2       
@export var dash_cooldown: float = 2.0     
@export_flags_2d_physics var layers_to_ignore_during_dash: int = 0 

# --- REFERÊNCIAS AO NÓ FILHO ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D 
@onready var collision_shape: CollisionShape2D = $CollisionShape2D 

var speed: float = 202.0
var is_dashing: bool = false
var can_dash: bool = true
var dash_timer: float = 0.0
var cooldown_timer: float = 0.0
var dash_dir: float = 1.0
var original_collision_mask: int = 0
var air_jumps_used: int = 0
var can_move := true

# Variáveis para guardar os valores originais da cápsula (Altura e Posição)
var original_shape_height: float = 0.0
var original_shape_position: Vector2 = Vector2.ZERO
	
	

func _ready() -> void:
	speed = base_speed
	original_collision_mask = collision_mask
	
	# Salva os valores originais da Shape da Cápsula no início do jogo
	if collision_shape and collision_shape.shape is CapsuleShape2D:
		var capsule = collision_shape.shape as CapsuleShape2D
		original_shape_height = capsule.height
		original_shape_position = collision_shape.position

func lock() -> void:
	can_move = false
	velocity.x = 0.0
	if is_dashing:
		end_dash()
	
func unlock() -> void:
	can_move = true

func _physics_process(delta: float) -> void:
	
	# Captura de Inputs de Movimento e Agachamento
	var direction := Input.get_axis("left", "right")
	var is_crouching_input = Input.is_action_pressed("crounch") and is_on_floor()
	
	# 1. Gerenciamento do Cooldown do Dash
	if not can_dash:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			can_dash = true
			print("Dash recarregado! Pronto para uso.")
			
	# Player travado (durante transição de cena): só gravidade, sem input
	if not can_move:
		if not is_on_floor():
			velocity += get_gravity() * delta
			play_animation_safe("Falling")
		else:
			velocity.x = 0.0
			play_animation_safe("Idle")
		move_and_slide()
		return
		
	# 2. Estado de Dash (Prioridade Máxima)
	if is_dashing:
		play_animation_safe("Roll")
		dash_timer -= delta
		velocity.x = dash_dir * (dash_distance / dash_duration)
		velocity.y = 0 
		move_and_slide()
		
		if dash_timer <= 0.0:
			end_dash()
		return

	# Acionar o Dash
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash()

	# 3. Gravidade e Velocidade de Ar/Chão
	if not is_on_floor():
		velocity += get_gravity() * delta
		speed = air_speed
	else:
		speed = base_speed
		air_jumps_used = 0  # tocou o chão: restaura o pulo duplo

	# Lógica de Pulo
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			# No chão: só pula se não estiver agachado
			if not is_crouching_input:
				velocity.y = JUMP_VELOCITY
		elif air_jumps_used < MAX_AIR_JUMPS:
			# No ar: pulo duplo
			velocity.y = JUMP_VELOCITY * DOUBLE_JUMP_MULTIPLIER
			air_jumps_used += 1


	# Aplicar velocidade horizontal padrão
	if direction != 0:
		velocity.x = direction * speed
		dash_dir = direction
		animated_sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# ==========================================
	# MÁQUINA DE ESTADOS DE ANIMAÇÃO E COLISÃO
	# ==========================================
	
	if not is_on_floor():
		# --- ESTADOS NO AR ---
		_reset_crouch_collision()
		
		if velocity.y < 0:
			play_animation_safe("Jump")
		else:
			play_animation_safe("Falling")
			
	elif is_crouching_input:
		# --- ESTADO DE AGACHADO ---
		velocity.x = 0 
		
		# Reduz a altura da cápsula pela metade
		if collision_shape and collision_shape.shape is CapsuleShape2D:
			var capsule = collision_shape.shape as CapsuleShape2D
			capsule.height = original_shape_height / 2.0
			# Usa a altura real (a Godot pode ter limitado pelo radius)
			var height_diff : float = original_shape_height - capsule.height
			collision_shape.position.y = original_shape_position.y + height_diff / 2.0
		
		play_animation_safe("Crounched")
			
	else:
		# --- ESTADOS NO CHÃO (PARADO OU CORRENDO) ---
		_reset_crouch_collision()
		
		if direction != 0:
			play_animation_safe("Run")
		else:
			play_animation_safe("Idle")

	move_and_slide()

# Função auxiliar para evitar reiniciar a mesma animação a cada frame
func play_animation_safe(anim_name: String) -> void:
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

# Restaura a altura e posição originais da cápsula de pé SEM dar o pulinho
func _reset_crouch_collision() -> void:
	if collision_shape and collision_shape.shape is CapsuleShape2D:
		var capsule = collision_shape.shape as CapsuleShape2D
		if capsule.height != original_shape_height:
			capsule.height = original_shape_height
			collision_shape.position = original_shape_position
			
func start_dash() -> void:
	
	#função responsável por iniciar o dash.
	
	is_dashing = true
	can_dash = false
	dash_timer = dash_duration
	cooldown_timer = dash_cooldown
	
	if layers_to_ignore_during_dash != 0:
		collision_mask = collision_mask & ~layers_to_ignore_during_dash
	
	print("Dash iniciado! Recarga de 2 segundos iniciada...")

func end_dash() -> void:
	
	#função reponsável por finalizar o dash.
	
	is_dashing = false
	collision_mask = original_collision_mask
