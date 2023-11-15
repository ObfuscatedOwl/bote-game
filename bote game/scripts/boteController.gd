extends Node2D

@export var playerShip = true

var actions = {"throtU" : false, "throtD" : false, "ruddL" : false, "ruddR" : true}
var keybinds = {"W" : "throtU", "S" : "throtD", "A" : "ruddL", "D" : "ruddR"}
var throttle = 0.0 #from -1 to 1

var velocity = Vector2(0, 0)
var boteRotation = 0.0
var mass = 1
var rotorForce = 1.8
var rotorRunning = true
const forcePerDeltaSpeed = 10
var sideForce = 3.0
var drag = 0.012

var targetSpeed = 0.0
var rudd = 0.0

const maxSpeed = 35.0 #18.0
const acc = 0.6 #0.06
const maxRudd = 0.5
const ruddEffect = 0.05

signal formationOrder

var formationCommands = []
var formationLeader = null

@export var playerKeyControlled = false
var targetPos = Vector2(0, 0)
const closeEnough = 80
var metTarget = true
const slowDownDist = 100

const turningDistance = 150
var preTargetDone = false
var finalTarget = Vector2(0,0)

var isSunk = false

func getTrueLeader():
	if formationLeader == null:
		return null
	else:
		return formationLeader.internalGetLeader()
		
func internalGetLeader():
	if formationLeader == null:
		return self
	else:
		return formationLeader.internalGetLeader()

func getFollowers(deep):
	var followers = []
	for follower in formationOrder.get_connections():
		followers.append(follower["callable"].get_object())
		if deep:
			followers.append_array(follower["callable"].get_object().getFollowers(true))
			
	return followers

func disband():
	var followers = getFollowers(true)
	print(followers)
	for follower in followers:
		follower.disconnectFollowers()
		follower.formationLeader = null
		
	if formationLeader == self:
		print("something is very wrong")
	
	if formationLeader != null:
		followers.append_array(formationLeader.disband())
	
	formationLeader = null
	disconnectFollowers()
	return followers

func disconnectFollowers():
	for command in formationCommands:
		formationOrder.disconnect(command[1].onFormationOrder)
	formationCommands = []

static func angleToAngleDiff(a, b):
	a = normalize_angle(a)
	b = normalize_angle(b)
	
	var diff0 = a - b
	var diff1
	if diff0 < 0:
		diff1 = diff0 + TAU
	else:
		diff1 = diff0 - TAU
	
	if abs(diff0) < abs(diff1):
		return diff0
	else:
		return diff1

static func normalize_angle(x):
	return fposmod(x + PI, 2.0*PI) - PI

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	navigation_agent.path_desired_distance = closeEnough
	navigation_agent.target_desired_distance = closeEnough
	call_deferred("actor_setup")
	
func _input(event):
	if event.is_action_pressed("runRotor"):
		rotorRunning = !rotorRunning
		print(rotorRunning)

func actor_setup():
	await get_tree().physics_frame
	
	navigation_agent.target_position = targetPos
	#since we're not going to a target immediately this may not be needed

func _process(delta):
	if playerKeyControlled:
		for key in keybinds.keys():
			actions[keybinds[key]] = Input.is_action_pressed(key)
		
		if actions["ruddL"]:
			rudd += 0.06 * delta
		if actions["ruddR"]:
			rudd -= 0.06 * delta
		
		if actions["throtU"]:
			targetSpeed += acc * delta
		if actions["throtD"]:
			targetSpeed -= acc * delta
			
	elif not navigation_agent.is_navigation_finished(): #not metTarget
		var next_path_position = navigation_agent.get_next_path_position()
		
		targetSpeed = maxSpeed * (position - next_path_position).length() / slowDownDist
		rudd = angleToAngleDiff(boteRotation, position.angle_to_point(next_path_position))
		metTarget = (position - next_path_position).length() <= closeEnough
	
	elif not preTargetDone:
		preTargetDone = true
		targetPos = finalTarget
		navigation_agent.target_position = finalTarget
	else:
		targetSpeed = 0
		rudd = 0
	
	rudd = clamp(rudd, -maxRudd, maxRudd)
	targetSpeed = clamp(targetSpeed, -maxSpeed, +maxSpeed)
	
	if isSunk:
		rudd = 0
		targetSpeed = 0
	
	moveBote(rudd, targetSpeed, delta)
	rotation = boteRotation
	#$bote2pointOh.rotation = boteRotation + PI/2
	#$"health/hitbox".rotation = boteRotation
	
	formationOrder.emit(getGlobalCommands())

func moveBote(rudd, targetSpeed, delta):
	var parallel = Vector2.from_angle(boteRotation)
	var currentSpeed = parallel.dot(velocity)
	if rotorRunning:
		velocity += parallel * clamp((targetSpeed - currentSpeed) * forcePerDeltaSpeed, -rotorForce, rotorForce) / mass
	#velocity -= parallel * velocity.length() * drag
	velocity *= pow(10, -drag * delta)
	
	var sideways = Vector2.from_angle(boteRotation - PI/2)
	var sidewaysSpeed = sideways.dot(velocity)
	velocity -= delta * sideways * sidewaysSpeed * sideForce / mass
	
	var velocityAngle = velocity.angle()
	var alpha = velocityAngle - boteRotation
	boteRotation += delta * cos(rudd) * velocity.length() * sin(alpha - rudd) * ruddEffect
	
	position += velocity * delta
	
	$"bote2pointOh/rudder".rotation = PI + rudd 

func getGlobalCommands():
	var commands = []
	for command in formationCommands:
		commands.append([command[0].rotated(boteRotation) + position, command[1]])
	return commands

func enactOrder(pos, desiredAngle):
	if desiredAngle == null:
		preTargetDone = true
		targetPos = pos
		navigation_agent.target_position = pos
	else:
		preTargetDone = false
		targetPos = pos - Vector2.from_angle(desiredAngle) * turningDistance
		navigation_agent.target_position = targetPos
		finalTarget = pos
		
	metTarget = false

func onOrder(pos, desiredAngle):
	if not isSunk:
		enactOrder(pos, desiredAngle)
		print("order recieved maam")

func onFormationOrder(commands):
	if not isSunk:
		for command in commands:
			if command[1] == self:
				enactOrder(command[0], null)

func canBeControlled(id):
	#do something to ensure id is correct
	if isSunk:
		return false
	return true
		
func sink():
	disband()
	#also go about removing self from formations
	isSunk = true

func getPosition():
	return position
func getVelocity():
	return velocity
