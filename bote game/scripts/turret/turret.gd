extends Node2D

const bullet = preload("res://scenes/bullet.tscn")
var bulletNode

const g = -10
const muzzleSpeed = 100
var reloadFull = 4
var reloading = 20

const adjustmentIterations = 10

var targeting = false
var targetInRange = false
var target: Node2D

var relTargetVel: Vector2
var relTargetPos: Vector2
var adjustedTarget = null
var targetInaccuracy = Vector2.ZERO

const turretTurnSpeed = 0.8
@export var maxRotation: float
@export var startRotation: float
var goalRotation = 0

const turretElevationSpeed = 0.4
@export var startElevation: float
var goalElevation = startElevation
var currentElevation = startElevation

func _ready():
	startRotation = rotation

func _process(delta):
	if targeting:
		adjustedTarget = adjustAim()
		goalRotation = adjustedTarget.angle()
		goalElevation = findElevation(adjustedTarget.length())

		targetInRange = true
		relTargetVel = target.velocity
	
	else:
		goalElevation = startElevation
		goalRotation = startRotation
	
	if (goalElevation == null):
		targetInRange = false
		goalElevation = startElevation
	
	# Clamps rotation speed against maxDTurn & rotation against maxRotation
	var maxDTurn = delta * turretTurnSpeed
	rotation = clamp(rotation - maxDTurn, goalRotation, rotation + maxDTurn)
	rotation = clamp(startRotation - maxRotation, rotation, startRotation + maxRotation)
	
	# Identical, but with elevation instead (startElevation is the centre between 0 elevation & maxElevation) - DOES NOT CONSIDER FIRING OVER OBSTRUCTIONS
	var maxDElevation = delta * turretElevationSpeed
	currentElevation = clamp(currentElevation - maxDElevation, goalElevation, currentElevation + maxDTurn)
	currentElevation = clamp(0, currentElevation, startElevation * 2)
	
	if (reloading < reloadFull):
		reloading += delta
	elif (rotation == goalRotation and currentElevation == goalElevation and targetInRange):
		reloading = 0
		fire(adjustedTarget)

func adjustAim():
	relTargetPos = target.position - position

	var movedTarget = relTargetPos
	var adjustedTimeToStrike = null
	
	targetInRange = true
	for adjustment in range(adjustmentIterations):
		adjustedTimeToStrike = timeToStrike(movedTarget.length())
		if (adjustedTimeToStrike != null):
			movedTarget = relTargetPos + relTargetVel * timeToStrike(movedTarget.length())
		else:
			break
	
	return movedTarget if targetInRange else relTargetPos

func timeToStrike(range):
	var requiredElevation = findElevation(range)
	if (requiredElevation != null):
		return range / (muzzleSpeed * cos(requiredElevation))
	return null

func findElevation(range):
	var m2Parameter = (g/2) * pow(range/muzzleSpeed, 2)
	
	# Check within range
	var b24ac = pow(range, 2) - 4 * pow(m2Parameter, 2)
	if (b24ac < 0):
		return null
	
	# Elevation required by the turret to strike the target
	return atan((sqrt(b24ac) - range) / (2 * m2Parameter))

func fire(target):
	$"Smoke".emitting = true
	$"Fire".emitting = true
	var newBullet = bullet.instantiate()
	if bulletNode != null:
		bulletNode.add_child(newBullet)

	newBullet.position = position
	newBullet.velocity = Vector2.from_angle(rotation) * muzzleSpeed * cos(currentElevation)
	newBullet.zSpeed = muzzleSpeed * sin(currentElevation)
