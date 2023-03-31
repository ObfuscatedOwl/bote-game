extends Camera2D

var actions = {"ui_up" : false, "ui_down" : false, "ui_left" : false, "ui_right" : false, "zoom_in" : false, "zoom_out" : false}

const moveSpeed = 500
const zoomRate = 0.5

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
		dy -= moveSpeed*delta
	if actions["ui_down"]:
		dy += moveSpeed*delta
	if actions["ui_left"]:
		dx -= moveSpeed*delta
	if actions["ui_right"]:
		dx += moveSpeed*delta
	
	if actions["zoom_in"]:
		zoom *= pow(10.0, zoomRate*delta)
	if actions["zoom_out"]:
		zoom *= pow(10.0, -zoomRate*delta)
	
	offset.x += dx / zoom.x
	offset.y += dy / zoom.x
