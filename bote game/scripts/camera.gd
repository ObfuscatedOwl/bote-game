extends Camera2D

var actions = {"ui_up" : false, "ui_down" : false, "ui_left" : false, "ui_right" : false, "zoom_in" : false, "zoom_out" : false}

const moveSpeed = 4
const zoomRate = 0.03

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	pass

func _process(delta):
	
	for key in actions.keys():
		actions[key] = Input.is_action_pressed(key)
	
	var dx = 0
	var dy = 0
	if actions["ui_up"]:
		dy -= moveSpeed
	if actions["ui_down"]:
		dy += moveSpeed
	if actions["ui_left"]:
		dx -= moveSpeed
	if actions["ui_right"]:
		dx += moveSpeed
	
	if actions["zoom_in"]:
		zoom *= pow(10.0, zoomRate)
	if actions["zoom_out"]:
		zoom *= pow(10.0, -zoomRate)
	
	offset.x += dx / zoom.x
	offset.y += dy / zoom.x
