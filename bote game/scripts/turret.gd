extends Node2D

var reloadFull = 20
var reloading = 20

var targetingType = "global"
var globalTarget = Vector2(1, 1)
var boteTarget = null
const turretTurnSpeed = 0.2

var relativeTurn = 0

func _ready():
	position = Vector2(2, 2)

func _process(delta):
	if (reloading < reloadFull):
		reloading += delta
	else:
		reloading = 0
		fire()
	
	# Remember turning can only occur if ship not blocking angle! IMPLEMENT THIS
	if (targetingType == "global"):
		relativeTurn = (globalTarget - position).angle() - rotation
		if relativeTurn:
			rotation += abs(relativeTurn)/relativeTurn * delta * turretTurnSpeed
	elif (targetingType == "bote"):
		pass

func fire():
	$"Smoke".emitting = true
	$"Fire".emitting = true
