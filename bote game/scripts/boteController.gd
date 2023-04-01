extends Node2D

var actions = {"throtU" : false, "throtD" : false, "ruddL" : false, "ruddR" : true}
var keybinds = {"W" : "throtU", "S" : "throtD", "A" : "ruddL", "D" : "ruddR"}
var throttle = 0.0 #from -1 to 1

var velocity = Vector2(0, 0)
var mass = 1
var rotorForce = 1.8
var rotorRunning = true
const forcePerDeltaSpeed = 10
var sideForce = 3.0
var drag = 0.012

var targetSpeed = 0.0
var rudd = 0.0

const maxSpeed = 18.0
const acc = 0.06
const maxRudd = 0.5
const ruddEffect = 0.05

signal formationOrder

var formationCommands = []
var formationLeader = null

var formationIndex = null

func getFollowers():
	var followers = []
	for follower in formationOrder.get_connections():
		followers.append(follower["callable"].get_object())
		for subFollower in follower.getFollowers():
			followers.append(subFollower)
			
	return followers

const playerControlled = false
var targetPos = Vector2(0, 0)
const closeEnough = 80
var metTarget = true
const slowDownDist = 100

const turningDistance = 150
var preTargetDone = false
var finalTarget = Vector2(0,0)

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
	pass#$"..".order.connect(onOrder)
	#gonna try connecting from the holder's side
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
	if playerControlled:
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
		rudd = angleToAngleDiff(rotation, position.angle_to_point(next_path_position))
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
	
	var parallel = Vector2.from_angle(rotation)
	var currentSpeed = parallel.dot(velocity)
	if rotorRunning:
		velocity += delta * parallel * clamp((targetSpeed - currentSpeed) * forcePerDeltaSpeed, -rotorForce, rotorForce) / mass
	#velocity -= parallel * velocity.length() * drag
	velocity *= pow(10, -drag * delta)
	
	var sideways = Vector2.from_angle(rotation - PI/2)
	var sidewaysSpeed = sideways.dot(velocity)
	velocity -= delta * sideways * sidewaysSpeed * sideForce / mass
	
	var velocityAngle = velocity.angle()
	var alpha = velocityAngle - rotation
	rotation += delta * cos(rudd) * velocity.length() * sin(alpha - rudd) * ruddEffect
	
	position += velocity * delta
	
	$"rudder".rotation = PI + rudd 
	
	
	var commands = []
	for command in formationCommands:
		commands.append(command.rotated(rotation) + position)
	formationOrder.emit(commands)
	

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
	enactOrder(pos, desiredAngle)
	print("order recieved maam")

func onFormationOrder(commands):
	enactOrder(commands[formationIndex], null)
