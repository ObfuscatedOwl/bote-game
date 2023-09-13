@tool
extends Node2D


func _process(delta):
	queue_redraw()
	
func _draw():
	var maxRotation = get_parent().maxRotation
	var relRotation = get_parent().rotation + get_parent().startRotation
	draw_arc(Vector2.ZERO, 10, - maxRotation - relRotation, maxRotation - relRotation, 10, Color(0, 1, 0, 0.5), 1)
