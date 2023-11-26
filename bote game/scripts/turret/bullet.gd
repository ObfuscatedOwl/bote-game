extends Node2D

var velocity: Vector2
var zSpeed: float

var zPosition = 0
var zAcc = -10

var damage = 10

func _process(delta):
	position += velocity * delta
	zSpeed += zAcc * delta
	zPosition += zSpeed * delta

	if (zPosition < 0):
		queue_free()
