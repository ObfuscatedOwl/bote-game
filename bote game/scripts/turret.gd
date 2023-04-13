extends Node2D

#~~~~~~~ TEMPORARY CONSTANTS - SHOULD BE EXPORTED SCENEWIDE FROM MAIN ~~~~~~~#

const g = 10

#~~~~~~~ ... ~~~~~~~#

const bullet = preload("res://scenes/bullet.tscn")

const muzzleSpeed = 50
var reloadFull = 20
var reloading = 20

const adjustmentIterations = 5
var targeting = true
var globalTarget = Vector2(0, -40)

var relativeTargetVelocity = Vector2(-4, 0)
var adjustedTarget = Vector2.ZERO

const turretTurnSpeed = 0.2
var relativeTurn = 0

func _process(delta):
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

func adjustAim():
	var relativeTarget = globalTarget - position
	var movedTarget = relativeTarget
	
	for adjustment in range(adjustmentIterations):
		if inRange(movedTarget.length()):
			movedTarget = relativeTarget + relativeTargetVelocity * timeToStrike(movedTarget.length())
	
	
	adjustedTarget = movedTarget

func timeToStrike(x):
	return x / (cos(asin((g * x) / pow(muzzleSpeed, 2)) / 2) * muzzleSpeed)

func inRange(x):
	return (g * x) / pow(muzzleSpeed, 2) < 1

func fire():
	$"Smoke".emitting = true
	$"Fire".emitting = true
