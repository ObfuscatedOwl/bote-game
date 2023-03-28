extends Node2D

var actions = {"throtU" : false, "throtD" : false, "ruddL" : false, "ruddR" : true}
var keybinds = {"W" : "throtU", "S" : "throtD", "A" : "ruddL", "D" : "ruddR"}
var throttle = 0.0 #from -1 to 1

var velocity = Vector2(0, 0)
var mass = 1
var rotorForce = 0.0005
var rotorRunning = true
const forcePerDeltaSpeed = 10
var sideForce = 0.05
var drag = 0.0002

var targetSpeed = 0.0
var rudd = 0.0

const maxSpeed = 0.3
const acc = 0.001
const maxRudd = 0.5
const ruddEffect = 0.05

signal formationOrder

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
			rudd += 0.001
		if actions["ruddR"]:
			rudd -= 0.001
		
		if actions["throtU"]:
			targetSpeed += acc
		if actions["throtD"]:
			targetSpeed -= acc
			
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
		velocity += parallel * clamp((targetSpeed - currentSpeed) * forcePerDeltaSpeed, -rotorForce, rotorForce) / mass
	#velocity -= parallel * velocity.length() * drag
	velocity *= pow(10, -drag)
	
	var sideways = Vector2.from_angle(rotation - PI/2)
	var sidewaysSpeed = sideways.dot(velocity)
	velocity -= sideways * sidewaysSpeed * sideForce / mass
	
	var velocityAngle = velocity.angle()
	var alpha = velocityAngle - rotation
	rotation += cos(rudd) * velocity.length() * sin(alpha - rudd) * ruddEffect
	
	position += velocity
	
	$"rudder".rotation = PI + rudd 
	
	
	#print(targetSpeed)
	

func onOrder(pos, desiredAngle):
	
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
	
	print("order recieved maam")
