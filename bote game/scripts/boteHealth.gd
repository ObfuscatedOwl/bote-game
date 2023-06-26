extends Node2D

var health = 100.0
var maxHealth = 100.0

signal sink

func drawRectangle(pos, size, color):
	var pointsArr = PackedVector2Array([
		pos,
		Vector2(pos.x + size.x, pos.y),
		pos + size,
		Vector2(pos.x, pos.y + size.y)
	])
	#var antiRotation = Transform2D(global_rotation, Vector2.ZERO)
	draw_polygon(pointsArr, PackedColorArray([color]))

# Called when the node enters the scene tree for the first time.
func _ready():
	sink.connect($"..".sink)


func _draw():
	drawRectangle(Vector2(-20, -50), Vector2(40, 10), Color(1, 0, 0))
	var healthFraction = max(0, health/maxHealth)
	drawRectangle(Vector2(-20, -50), Vector2(40*healthFraction, 10), Color(0, 1, 0))
	if health <= 0:
		var major = Vector2(2, 2)
		var minor = Vector2(0.2, 0.2)
		var color = PackedColorArray([Color(1, 0, 0)])
		draw_polygon(PackedVector2Array([
			major+minor, major-minor, -major-minor, -major+minor
		]), color)
		major = major.rotated(PI/2)
		minor = minor.rotated(PI/2)
		draw_polygon(PackedVector2Array([
			major+minor, major-minor, -major-minor, -major+minor
		]), color)
		print("cross")
	else:
		print("no cross")

func _on_hitbox_entered(area):
	var areaParent = area.get_parent()
	if area.collision_layer == 2:
		bulletHit(areaParent)
		
func bulletHit(bullet):
	if health > 0:
		health -= bullet.damage
		print("Health decreased to " + str(health))
	bullet.queue_free()
	if health <= 0:
		sink.emit()
		print("noooo ahh imdead")
	queue_redraw()
	
