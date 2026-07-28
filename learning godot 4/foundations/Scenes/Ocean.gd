extends Node2D


@onready var plane: Sprite2D = $Plane
@onready var heli: Sprite2D = $Helicopter
@onready var eating_sound: AudioStreamPlayer = $EatingSound


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	plane.move_local_x(100.0 * delta)
	heli.move_local_x(100 * delta)
	
	if Input.is_action_just_pressed("ui_accept"):
		eating_sound.play()


	if Input.is_action_pressed("ui_left"):
		plane.rotate(-1.5 * delta)
	if Input.is_action_pressed("ui_right"):
		plane.rotate(1.5 * delta)
