extends Node2D

const bullet = preload("res://scenes/bullet.tscn")
var bulletNode

const g = -10
const muzzleSpeed = 100
var reloadFull = 4
var reloading = 20

const adjustmentIterations = 10

var targeting = false
var target: Vector2

var relTargetVel: Vector2
var relTargetPos: Vector2
var adjustedTarget = Vector2.ZERO

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
	
	if adjustedTarget != null:
		goalRotation = adjustedTarget.angle()
		goalElevation = findElevation(adjustedTarget.length())
	else:
		goalRotation = startRotation
	
	# Clamps rotation speed against maxDTurn & rotation against maxRotation
	var maxDTurn = delta * turretTurnSpeed
	rotation = clamp(rotation - maxDTurn, goalRotation, rotation + maxDTurn)
	rotation = clamp(startRotation - maxRotation, rotation, startRotation + maxRotation)
	
	# Identical, but with elevation instead (startElevation is the centre between 0 elevation & maxElevation) - DOES NOT CONSIDER FIRING OVER OBSTRUCTIONS
	var maxDElevation = delta * turretElevationSpeed
	rotation = clamp(currentElevation - maxDElevation, goalElevation, currentElevation + maxDTurn)
	rotation = clamp(0, currentElevation, startElevation * 2)
	
	if (reloading < reloadFull):
		reloading += delta
	else:
		if (rotation == goalRotation and currentElevation == goalElevation and adjustedTarget != null):
			reloading = 0
			fire()

func adjustAim():
	relTargetPos = target
	var movedTarget = relTargetPos
	
	for adjustment in range(adjustmentIterations):
		var adjustedTimeToStrike = timeToStrike(movedTarget.length())
		if (adjustedTimeToStrike != null):
			movedTarget = relTargetPos + relTargetVel * timeToStrike(movedTarget.length())
		else:
			movedTarget = null
			break
	
	return movedTarget if (movedTarget != null) else relTargetPos

func timeToStrike(range):
	var requiredElevation = findElevation(range)
	if (requiredElevation != null):
		return range / (muzzleSpeed * cos(requiredElevation))
	return null

func findElevation(range):
	var m2Parameter = g/2 * pow(range/muzzleSpeed, 2)
	
	# Check within range
	var b24ac = pow(range, 2) - 4 * pow(m2Parameter, 2)
	if (b24ac < 0):
		return null
	
	# Elevation required by the turret to strike the target
	return atan(-(range + sqrt(b24ac)) / (2 * m2Parameter))

func fire():
	$"Smoke".emitting = true
	$"Fire".emitting = true
	var newBullet = bullet.instantiate()
	if bulletNode != null:
		bulletNode.add_child(newBullet)
	newBullet.position = position
	newBullet.velocity = Vector2.from_angle(rotation) * muzzleSpeed * cos(currentElevation)
