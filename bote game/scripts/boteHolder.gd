extends Node2D

signal order

enum {OFF, LINE, CLUSTER}
var formationStatus = OFF #off, line, cluster
var botesInLine
var clusterLeader
var clusterFollower

var selecting = false
var selectStart = Vector2(0, 0)
var selected = []

var targetPosition = Vector2(0, 0)

const angleDontCare = 10
const clickRadius = 50
const lineSpread = -200

# Called when the node enters the scene tree for the first time.
func _ready():
	formationStatus = OFF
	resetSelections()


	

	
func getControllableBotes():
	var children = get_children()
	var controllableBotes = []
	for child in children:
		if child.canBeControlled(null):
			controllableBotes.append(child)
	return controllableBotes
	


func selectBote(bote):
	if bote.getTrueLeader() in selected:
		pass
	elif bote.getTrueLeader() != null:
		selected.append(bote.getTrueLeader())
		order.connect(bote.getTrueLeader().onOrder)
	else:
		selected.append(bote)
		order.connect(bote.onOrder)

func deselectBotes():
	selecting = false
	for bote in selected:
		order.disconnect(bote.onOrder)
	selected = []
	
func givePositionOrder():
	if globalToMouseDist(targetPosition) > angleDontCare:
		var desiredAngle = targetPosition.angle_to_point(get_global_mouse_position())
		order.emit(targetPosition, desiredAngle)
		print("that angle DO care")
	else:
		order.emit(targetPosition, null)
		print("that angle dont care")
		
func addClosestToList(inList, outList):
	var shortestDistance = INF
	var closestBote = null
	for bote in inList:
		var boteMouseDist = globalToMouseDist(bote.position)
		if boteMouseDist < shortestDistance and not (outList.has(bote)):
			shortestDistance = boteMouseDist
			closestBote = bote
	if shortestDistance < clickRadius:
		outList.append(closestBote)

func resetSelections():
	deselectBotes()
	botesInLine = []
	clusterLeader = null
	clusterFollower = null
	
func connectBotes(leader, follower, relPos):
	follower.formationLeader = leader
	leader.formationCommands.append([relPos, follower])
	leader.formationOrder.connect(follower.onFormationOrder)
	
func prepareForFormation(bote):
	if bote.formationLeader != null:
		bote.disband() #hopefully formationLeader always gets set back to null after?
	

		






func enactLineOrder():
	for bote in botesInLine:
		prepareForFormation(bote)
	
	order.connect(botesInLine[0].onOrder)
	givePositionOrder() #assuming there are some in the list
	
	#make sure not to allow deactivating the line mode while right click held? QOL stuff
	
	for i in range(botesInLine.size()-1):
		botesInLine[i].formationCommands = []
		connectBotes(botesInLine[i], botesInLine[i+1], Vector2(lineSpread, 0))
		
	selected = [botesInLine[0]]
	botesInLine = []
	formationStatus = OFF







func _process(_delta):
	queue_redraw()
