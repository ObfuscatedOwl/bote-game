extends Node2D

var velocity: Vector2
var damage = 10
var target
var initialPosition

func _process(delta):
	position += velocity * delta
