extends Node2D

#~~~~~~~ TEMPORARY CONSTANTS - SHOULD BE EXPORTED SCENEWIDE FROM MAIN ~~~~~~~#

const g = 10

#~~~~~~~ ... ~~~~~~~#

const muzzleSpeed = 50
var reloadFull = 20
var reloading = 20

const adjustmentIterations = 5
var targeting = true
var globalTarget = Vector2(0, -10)

var relativeTargetVelocity = Vector2(0, 0)
var adjustedTarget = Vector2.ZERO

const turretTurnSpeed = 1
var relativeTurn = 0

func _ready():
	position = Vector2.ZERO

func _process(delta):
	globalTarget += relativeTargetVelocity * delta
	
	if (reloading < reloadFull):
		reloading += delta
	else:
		reloading = 0
		fire()

	if targeting:
		adjustAim()
		relativeTurn = adjustedTarget.angle() - rotation
		if relativeTurn:
			rotation += abs(relativeTurn)/relativeTurn * delta * turretTurnSpeed
	else:
		# Return to default position
		relativeTurn = -rotation
		if relativeTurn:
			rotation += abs(relativeTurn)/-relativeTurn * delta * turretTurnSpeed
	
	queue_redraw()

func _draw():
	draw_circle(to_local(globalTarget), 10, Color(0, 0, 0))

func adjustAim():
	var relativeTarget = globalTarget - position
	
	for adjustment in range(adjustmentIterations):
		print(adjustment)
		if inRange(relativeTarget.length()):
			relativeTarget += relativeTargetVelocity * timeToStrike(relativeTarget.length())
	
	adjustedTarget = relativeTarget

func timeToStrike(x):
	print(x / cos(asin((g * x) / pow(muzzleSpeed, 2)) / 2))
	return x / cos(asin((g * x) / pow(muzzleSpeed, 2)) / 2)

func inRange(x):
	return (g * x) / pow(muzzleSpeed, 2) < 1

func fire():
	$"Smoke".emitting = true
	$"Fire".emitting = true
