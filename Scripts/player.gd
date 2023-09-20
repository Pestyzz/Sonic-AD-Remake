extends CharacterBody2D

#Variables
var speed : float = 0.0
var motion = Vector2.ZERO

#Variables globales, pueden ser modificadas en el inspector
@export var ACC_SPEED : float = 100
@export var DEC_SPEED : float = 300
@export var JUMP_HEIGHT : float = -300
@export var MAX_SPEED : float = 400
@export var GRAVITY : float = 16.0

#Variables de estado
var running : bool
@onready var can_jump : bool = false
var jumping : bool
var is_grounded : bool

#Las físicas del personaje se actualizan cada frame
func _process(delta):
	motion_ctrl(delta)

#Obtiene el valor de la direccion x del pj
func get_dir() -> Vector2:
	#Eje x
	#Derecha = 1
	#Izquierda = -1
	#Ninguno = 0
	var axis = Vector2.ZERO
	axis.x = Input.get_axis('left', 'right')
	return axis


func motion_ctrl(delta):
	velocity = motion
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
	
	anim()
	run(delta)
	jump(delta)
	move_and_slide()

#Animaciones Sonic
func anim():
	#Si está en dir-derecha, no flip.
	if get_dir().x == 1:
		$AnimatedSprite2D.flip_h = false
	#Si está en dir-izquierda, flips.
	elif get_dir().x == -1:
		$AnimatedSprite2D.flip_h = true
	#---------------------------------------------
	#Walk/Jogg/Run animations control.
	if is_on_floor():
		if running == true or speed != 0:
			if speed > 0 and speed < 200:
				$AnimatedSprite2D.play("walking")
			elif speed > 200 and speed < 270:
				$AnimatedSprite2D.play("jogging")
			else:
				$AnimatedSprite2D.play("running")
		else:
			$AnimatedSprite2D.play("standing")
	#---------------------------------------------
	#Jump animation control.
	if not is_on_floor() and !can_jump:
		$AnimatedSprite2D.play("jumping")

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

func jump(delta):
	#Se define si se puede saltar o no
	if is_on_floor():
		can_jump = true
		jumping = false
	else:
		jumping = true		
		can_jump = false
	#-------------------------
	if Input.is_action_just_pressed('jump'):
		if is_on_floor() or can_jump:
			motion.y = JUMP_HEIGHT
			jumping = true
			can_jump = false
