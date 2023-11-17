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

func drawRectangle(pos, size, color):
	var pointsArr = PackedVector2Array([
		pos,
		Vector2(pos.x + size.x, pos.y),
		pos + size,
		Vector2(pos.x, pos.y + size.y)
	])
	draw_polygon(pointsArr, PackedColorArray([color]))
	
func globalToMouseDist(globalPos):
	var zoom = $"../Camera2D".zoom.x
	return (globalPos - get_global_mouse_position()).length() / zoom
	
func getControllableBotes():
	var children = get_children()
	var controllableBotes = []
	for child in children:
		if child.canBeControlled(null):
			controllableBotes.append(child)
	return controllableBotes
	
func selectBotes():
	var childs = getControllableBotes()
	for child in childs:
		var xyCheck = (child.position - selectStart) * (child.position - get_global_mouse_position())
		if (xyCheck.x < 0 and xyCheck.y < 0):
			selectBote(child)

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
	
func _draw():
	
	draw_circle(targetPosition, 30, Color(1, 1, 1, 0.2))
	
	if selecting:
		drawRectangle(selectStart, get_global_mouse_position() - selectStart, Color(0.1, 0.4, 0.1, 0.5))
	for bote in selected:
		draw_arc(bote.position, 50, 0, TAU, 20, Color(0, 0, 1), 2)
		formationLines(bote)
	for bote in botesInLine:
		draw_arc(bote.position, 52, 0, TAU, 20, Color(0, 1, 0), 2)
	if clusterLeader != null:
		draw_arc(clusterLeader.position, 30, -PI/6, -5*PI/6, 10, Color(1, 1, 0), 5) #crown
	if clusterFollower != null:
		draw_arc(clusterFollower.position, 30, PI/6, 5*PI/6, 10, Color(1, 1, 0), 5) #subCrown?
		
func formationLines(bote):
	for command in bote.getGlobalCommands():
		draw_line(command[1].position, command[0], Color(1, 1, 0))
		draw_arc(command[0], 3, 0, TAU, 20, Color(1, 1, 0), 6)
	for follower in bote.getFollowers(true):
		draw_arc(follower.position, 54, 0, TAU, 20, Color(1, 1, 0), 2)
		formationLines(follower)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1 and formationStatus == OFF: #primary mouse button
			if event.pressed:
				selecting = true
				selectStart = get_global_mouse_position()
			else:
				resetSelections()
				selectBotes()
				queue_redraw()
		
		if event.button_index == 2:
			if event.pressed:
				targetPosition = get_global_mouse_position()
			if not event.pressed  and formationStatus == OFF:
				givePositionOrder()

	
	if event is InputEventMouseMotion:
		pass#if selecting:
		#	queue_redraw()
		#queue_redraw() called in process, unnecessary i think
	
	if event.is_action_pressed("lineOrder"):
		lineActivate()
			
	if event is InputEventMouseButton and formationStatus == LINE:
		if event.pressed and event.button_index == 1:
			addClosestToList(getControllableBotes(), botesInLine)
				
		if not event.pressed and event.button_index == 2 and botesInLine.size() != 0:
			enactLineOrder()
	
	if event.is_action_pressed("clusterOrder"):
		clusterActivate()
		
	if event is InputEventMouseButton and formationStatus == CLUSTER:
		if event.pressed and event.button_index == 1:
			clusterSelection()
		if event.pressed and event.button_index == 2 and clusterLeader != null and clusterFollower != null:
			enactClusterOrder()
				
	if event.is_action_pressed("disband"):
		for bote in selected:
			selected.append_array(bote.disband()) #add the released botes to the selecteds

func lineActivate():
	if formationStatus == LINE:
		print("line mode D E A C T I V A T E D") #cancel position order stage
		formationStatus = OFF
		resetSelections()
	elif formationStatus == OFF:
		resetSelections()
		formationStatus = LINE #initiate line mode
		print("line mode A C T I V A T E D")

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

func clusterActivate():
	if formationStatus != CLUSTER:
		formationStatus = CLUSTER
		resetSelections()
		print("C L U S I V A T E")
	else:
		formationStatus = OFF
		var putInSelected = clusterLeader
		resetSelections()
		selectBote(putInSelected)
		print("D E C L U S I V A T E")

func clusterSelection():
	if clusterLeader == null:
		var clusterLeaderList = []
		addClosestToList(getControllableBotes(), clusterLeaderList)
		if clusterLeaderList != []:
			clusterLeader = clusterLeaderList[0]
			selected = [clusterLeader]
			prepareForFormation(clusterLeader)
	else:
		var clusterFollowerList = []
		addClosestToList(getControllableBotes(), clusterFollowerList)
		if clusterFollowerList != []:
			if clusterFollowerList[0] != clusterLeader:
				clusterFollower = clusterFollowerList[0]

func enactClusterOrder():
	prepareForFormation(clusterFollower)
	print("give clusterOrder")
	var formationPos = (clusterLeader.transform.affine_inverse())*get_global_mouse_position()
	connectBotes(clusterLeader, clusterFollower, formationPos)
	clusterFollower = null

func _process(_delta):
	queue_redraw()
