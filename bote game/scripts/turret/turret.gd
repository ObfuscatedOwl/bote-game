extends Node2D

#~~~~~~~ TEMPORARY CONSTANTS - SHOULD BE EXPORTED SCENEWIDE FROM MAIN ~~~~~~~#

const g = 10

#~~~~~~~ ... ~~~~~~~#

const bullet = preload("res://scenes/bullet.tscn")
var bulletNode

const muzzleSpeed = 50
var reloadFull = 4
var reloading = 20

const adjustmentIterations = 10
var targeting = false
var target : Node2D
var relTargetPos

var adjustedTarget = Vector2.ZERO

const turretTurnSpeed = 0.8
var goalRotation = 0
@export var maxRotation : float
@export var startRotation: float

func _ready():
	startRotation = rotation

func _process(delta):
	#globalTarget += relativeTargetVelocity * delta

	if targeting:
		adjustAim()
		goalRotation = adjustedTarget.angle()
	else:
		# Return to default position
		goalRotation = startRotation
	var maxDTurn = delta * turretTurnSpeed
	rotation = clamp(rotation - maxDTurn, goalRotation, rotation + maxDTurn)
	rotation = clamp(startRotation - maxRotation, rotation, startRotation + maxRotation)

	if (reloading < reloadFull):
		reloading += delta
	else:
		if rotation == goalRotation:
			reloading = 0
			fire()
	
func adjustAim():
	var trans = get_global_transform()
	var transInv = trans.affine_inverse()
	var rotInv = Transform2D(-trans.get_rotation(), Vector2.ZERO)
	relTargetPos = target.getPosition() - position#transInv *target.getPosition()
	print(relTargetPos)
	var relTargetVel = target.getVelocity()#rotInv * target.getVelocity()
	var movedTarget = relTargetPos
	
	for adjustment in range(adjustmentIterations):
		movedTarget = relTargetPos + relTargetVel * timeToStrike(movedTarget.length())
	if not inRange(movedTarget.length()):
		movedTarget = relTargetPos
	
	adjustedTarget = movedTarget

func timeToStrike(x):
	return x / (cos(asin((g * x) / pow(muzzleSpeed, 2)) / 2) * muzzleSpeed)

func inRange(x):
	return (g * x) / pow(muzzleSpeed, 2) < 1

func fire():
	$"Smoke".emitting = true
	$"Fire".emitting = true
	var newBullet = bullet.instantiate()
	if bulletNode != null:
		bulletNode.add_child(newBullet)
	newBullet.position = position
	newBullet.velocity = Vector2.from_angle(rotation) * muzzleSpeed
