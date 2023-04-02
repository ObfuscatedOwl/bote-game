extends Node2D

var reloadFull = 20
var reloading = 20

var target = Vector2(1, 1)
var targetingPos = true
const turnSpeed = 0.2

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
	if targetingPos:
		relativeTurn = (target - position).angle() - rotation
		if relativeTurn:
			rotation += abs(relativeTurn)/relativeTurn * delta * turnSpeed

func fire():
	$"Smoke".emitting = true
	$"Fire".emitting = true
