extends Node2D

const turret = preload("res://scenes/turret.tscn")
const bote = preload("res://scenes/bote.tscn")
var newTurret
var newBote

func _ready():
	newTurret = turret.instantiate()
	add_child(newTurret)
	newTurret.bulletNode = $bullets
	#newTurret.position = Vector2(100, 0)
	#newTurret.startRotation = PI
	newBote = bote.instantiate()
	$boteHolder.add_child(newBote)
	newBote.position = Vector2(-250, -40)
	newTurret.target = newBote

func _draw():
	'''if newTurret.relTargetPos:
		draw_circle(newTurret.relTargetPos, 2, Color(1, 1, 1))
	else:
		print("it is nil")'''
	if $turret.adjustedTarget:
		draw_circle($turret.adjustedTarget, 2, Color(1, 0, 0, 1))


func _process(delta):
	queue_redraw()
	newTurret.targeting = true
