@tool
extends Node2D


func _process(delta):
	queue_redraw()
	
func _draw():
	#print(get_parent().startRotation)
	var maxRotation = $"..".maxRotation
	draw_arc(Vector2.ZERO, 10, -maxRotation, +maxRotation, 10, Color(0, 1, 0, 0.5), 1)
