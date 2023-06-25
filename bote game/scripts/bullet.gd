extends Node2D

var velocity:Vector2

func _process(delta):
	position += velocity * delta
