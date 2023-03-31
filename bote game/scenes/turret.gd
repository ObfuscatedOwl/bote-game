extends Node2D



var reloadFull = 20
var reloading = 20

func _ready():
	pass

func _process(delta):
	if (reloading < reloadFull):
		reloading += delta
	else:
		reloading = 0
		fire()

func fire():
	$"Smoke".emitting = true
	$"Fire".emitting = true
