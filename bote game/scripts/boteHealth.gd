extends Node2D

var health = 100.0
var maxHealth = 100.0

func drawRectangle(pos, size, color):
	var pointsArr = PackedVector2Array([
		pos,
		Vector2(pos.x + size.x, pos.y),
		pos + size,
		Vector2(pos.x, pos.y + size.y)
	])
	var antiRotation = Transform2D(global_rotation, Vector2.ZERO)
	draw_polygon(pointsArr * antiRotation, PackedColorArray([color]))

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _draw():
	drawRectangle(Vector2(-20, -50), Vector2(40, 10), Color(1, 0, 0))
	var healthFraction = health/maxHealth
	drawRectangle(Vector2(-20, -50), Vector2(40*healthFraction, 10), Color(0, 1, 0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	queue_redraw()


func _on_hitbox_entered(area):
	var areaParent = area.get_parent()
	if area.collision_layer == 2:
		health -= areaParent.damage
		print("Health decreased to " + str(health))
		areaParent.queue_free()
