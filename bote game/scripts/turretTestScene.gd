extends Node2D

const turret = preload("res://scenes/gun.tscn")

func _ready():
	var newTurret = turret.instantiate()
	add_child(newTurret)
