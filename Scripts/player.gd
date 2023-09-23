extends CharacterBody2D

#Variables
var speed : float = 0.0
var motion : Vector2 = Vector2.ZERO

#Variables globales, pueden ser modificadas en el inspector
@export var ACC_SPEED : float = 100
@export var DEC_SPEED : float = 300
@export var JUMP_HEIGHT : float = -300
@export var MAX_SPEED : float = 400
@export var GRAVITY : float = 16.0

#Variables de estado
@onready var can_jump : bool = false
@onready var can_spindash : bool = false
var jumping : bool
var running : bool
var look_up : bool
var crouch : bool

#Variable anim_sprite inicializada al cargar que obtiene la clase AnimationPlayer
@onready var anim_sprite : AnimationPlayer = get_node("Sprite2D/AnimationPlayer")
@onready var anim_tree : AnimationTree = get_node("Sprite2D/AnimationTree")
@onready var anim_tree_pb = anim_tree.get("parameters/playback")
#Variable que obtiene la clase Sprite2D al cargar
@onready var sprite : Sprite2D= get_node("Sprite2D")

func _ready():
	anim_tree.active = true

func _process(delta):
	animation()

#Las físicas del personaje se actualizan cada frame
func _physics_process(delta):
	motion_ctrl(delta)

#Obtiene el valor de la direccion x del pj
func get_dir() -> Vector2:
	#Eje x
	#Derecha = 1
	#Izquierda = -1
	#Ninguno = 0
	var axis : Vector2 = Vector2.ZERO
	axis.x = Input.get_axis('left', 'right')
	return axis

func motion_ctrl(delta):
	velocity = motion
	
	#Se aplica la gravedad al no estar en el suelo.
	if not is_on_floor():
		motion.y += GRAVITY * delta
		
	#Si la direción es diferente de cero, quiere decir que se está moviendo.
	if get_dir().x != 0:
		#Para moverse motion.x calcula la direcion[1/-1] por la velocidad que va incrementando.
		motion.x = get_dir().x * speed
	else:
		#Esto hace que Sonic siga corriendo al dejar de presionar y disminuye su velocidad hasta 0.
		if motion.x < 0:
			motion.x = sign(-speed) * speed
		elif motion.x > 0:
			motion.x = sign(speed) * speed
	run(delta)
	jump()
	lookup(delta)
	move_and_slide()

#Animaciones Sonic
func animation():
	#Si está en dir-derecha, no flip.
	if get_dir().x == 1:
		sprite.scale.x = 1 
	#Si está en dir-izquierda, flip.
	elif get_dir().x == -1:
		sprite.scale.x = -1
	#---------------------------------------------
	#Walk/Jog/Run animations control.
	if is_on_floor():
		if running or speed != 0:
			anim_tree["parameters/States/Transition/transition_request"] = "moving"
			anim_tree["parameters/States/Walk-Jog-Run/Walk-Jog-Run/blend_position"] = speed
		elif is_on_floor() and !running and !look_up:
			anim_tree["parameters/States/Transition/transition_request"] = "standing"
	#---------------------------------------------
	#Jump animation control.
	if !can_jump:
		anim_tree["parameters/States/Transition/transition_request"] = "jumping"
	#---------------------------------------------
	#Look up animation control.
	if look_up:
		anim_tree["parameters/States/Look up/conditions/not_lookup"] = false
		anim_tree["parameters/States/Transition/transition_request"] = "lookup"
	else:
		anim_tree["parameters/States/Look up/conditions/not_lookup"] = true
		
#Funciones de estado
func run(delta):
	#Si el personaje está yendo en alguna dirección, está corriendo
	if get_dir().x == 1 or get_dir().x == -1:
		running = true
	else:
		running = false
		
	#Se define la velocidad de Sonic dependiendo de si está o no corriendo.
	if running:
		#La velocidad va incrementando a medida que pasa el tiempo.
		speed += ACC_SPEED * delta
		if speed >= MAX_SPEED:
			#Cuando la velocidad llegue al tope se mantiene ahí.
			speed = MAX_SPEED
	#Si no está corriendo la velocidad que tiene disminuye hasta cero.
	else:
		if speed > 0:
			#La velocidad va decreciendo por el tiempo.
			speed -= DEC_SPEED * delta
			if speed <= 0:
				#Si la velocidad llega al mínimo, se mantiene ahí.
				speed = 0

func jump():
	#Se define si se puede saltar o no
	if is_on_floor():
		can_jump = true
		jumping = false
	else:
		can_jump = false
	#-------------------------
	if is_on_floor() and Input.is_action_just_pressed('jump'):
		if can_jump:
			motion.y = JUMP_HEIGHT
			jumping = true
			can_jump = false

func lookup(delta):
	var target_camera_y : float = 0.0
	var camera_smoothing_speed : float = 2.0
	if is_on_floor() and Input.is_action_pressed("look up") and speed == 0:
		look_up = true
		target_camera_y = -60.0
	else:
		look_up = false
		target_camera_y = 0.0
	$Camera2D.position.y = lerp($Camera2D.position.y, target_camera_y, camera_smoothing_speed * delta)

func spin_dash():
	if is_on_floor() and crouch:
		if get_dir().x == 1 and Input.is_action_pressed("right"):
			can_spindash = true
		elif get_dir().x == -1 and Input.is_action_pressed("left"):
			can_spindash = true;
