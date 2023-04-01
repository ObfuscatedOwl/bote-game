extends Node2D

signal order

var selecting = false
var selectStart = Vector2(0, 0)
var selected = []

var targetPosition = Vector2(0, 0)

const angleDontCare = 10
const clickRadius = 50

var lineMode = "off" #off, selecting, awaitingPosition
var botesInLine = []

func drawSquare(pos, size, color):
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
	return get_children()
	
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

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _draw():
	
	draw_circle(targetPosition, 30, Color(1, 1, 1, 0.2))
	
	if selecting:
		drawSquare(selectStart, get_global_mouse_position() - selectStart, Color(0.1, 0.4, 0.1, 0.5))
	for bote in selected:
		draw_arc(bote.position, 50, 0, TAU, 20, Color(0, 0, 1), 2)
	for bote in botesInLine:
		draw_arc(bote.position, 52, 0, TAU, 20, Color(0, 1, 0), 2)

func _input(event):
	if event.get_class() == "InputEventMouseButton":
		if event.button_index == 1 and lineMode == "off": #primary mouse button
			if event.pressed:
				selecting = true
				selectStart = get_global_mouse_position()
				queue_redraw()
			else:
				deselectBotes()
				var childs = getControllableBotes()
				for child in childs:
					var xyCheck = (child.position - selectStart) * (child.position - get_global_mouse_position())
					if (xyCheck.x < 0 and xyCheck.y < 0):
						selected.append(child)
						order.connect(child.onOrder)
						#bababa check if it has followers and if so show the formation
					
				queue_redraw()
		if event.button_index == 2:
			if event.pressed:
				targetPosition = get_global_mouse_position()
			if not event.pressed  and lineMode == "off": #later add click and drag orders
				givePositionOrder()

	
	if event.get_class() == "InputEventMouseMotion":
		if selecting:
			queue_redraw()
	
	if event.is_action_pressed("lineOrder"):
		if lineMode == "selecting":
			print("line mode D E A C T I V A T E D") #cancel position order stage
			lineMode = "off"
			botesInLine = []
		elif lineMode == "off":
			deselectBotes()
			lineMode = "selecting" #initiate line mode
			print("line mode A C T I V A T E D")
		else:
			print("no botes selected!")
			#eventually make this into a ui bit. all of the line stuff i guess
			
	if event.get_class() == "InputEventMouseButton" and lineMode == "selecting":
		if event.pressed and event.button_index == 1:
			#line mode should never be true if no botes are selected. so gonna assume that selected has elements
			var shortestDistance = INF
			var closestBote = null
			for bote in getControllableBotes():
				var boteMouseDist = globalToMouseDist(bote.position)
				if boteMouseDist < shortestDistance and not (botesInLine.has(bote)):
					shortestDistance = boteMouseDist
					closestBote = bote
			if shortestDistance < clickRadius:
				botesInLine.append(closestBote)
				
		if not event.pressed and event.button_index == 2 and botesInLine.size() != 0:
			order.connect(botesInLine[0].onOrder)
			givePositionOrder() #assuming there are some in the list
			
			#make sure not to allow deactivating the line mode while right click held? QOL stuff
			
			for i in range(botesInLine.size()-1):
				botesInLine[i].formationLeader = botesInLine[0]
				botesInLine[i].formationCommands = [Vector2(-50, 0)]
				botesInLine[i+1].formationIndex = 0
				botesInLine[i].formationOrder.connect(botesInLine[i+1].onFormationOrder)
				
			botesInLine[-1].formationLeader = botesInLine[0]
			botesInLine = []
	

func _process(_delta):
	queue_redraw()
