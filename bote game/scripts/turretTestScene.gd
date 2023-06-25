extends Node2D

const turret = preload("res://scenes/gun.tscn")

func _ready():
	var newTurret = turret.instantiate()
	add_child(newTurret)
	newTurret.bulletNode = $bullets
	$bullets.add_child(newTurret)

func _draw():
	draw_circle($Turret.globalTarget, 2, Color(1, 1, 1, 0.5))
	draw_circle($Turret.adjustedTarget, 2, Color(1, 0, 0, 0.5))


func _process(delta):
	queue_redraw()