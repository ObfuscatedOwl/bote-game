extends Node2D

const turret = preload("res://scenes/gun.tscn")
const bote = preload("res://scenes/bote.tscn")
var newTurret
var newBote

func _ready():
	newTurret = turret.instantiate()
	add_child(newTurret)
	newTurret.bulletNode = $bullets
	$bullets.add_child(newTurret)
	newBote = bote.instantiate()
	$boteHolder.add_child(newBote)
	newBote.position = Vector2(250, -40)

func _draw():
	draw_circle($Turret.globalTarget, 2, Color(1, 1, 1, 0.5))
	draw_circle($Turret.adjustedTarget, 2, Color(1, 0, 0, 1))


func _process(delta):
	newTurret.globalTarget = newBote.position
	newTurret.relativeTargetVelocity = newBote.velocity
	queue_redraw()
