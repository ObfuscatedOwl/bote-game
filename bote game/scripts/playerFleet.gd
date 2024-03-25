extends Node2D


func drawRectangle(pos, size, color):
	var pointsArr = PackedVector2Array([
		pos,
		Vector2(pos.x + size.x, pos.y),
		pos + size,
		Vector2(pos.x, pos.y + size.y)
	])
	draw_polygon(pointsArr, PackedColorArray([color]))
    
func selectBotes():
	var childs = getControllableBotes()
	for child in childs:
		var xyCheck = (child.position - selectStart) * (child.position - get_global_mouse_position())
		if (xyCheck.x < 0 and xyCheck.y < 0):
			selectBote(child)
    
func globalToMouseDist(globalPos):
	var zoom = $"../Camera2D".zoom.x
	return (globalPos - get_global_mouse_position()).length() / zoom
    
    
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