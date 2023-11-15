extends Node2D

var velocity: Vector2
var damage = 10

func _process(delta):
	position += velocity * delta
