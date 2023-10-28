extends Node2D

var polygon1 = Polygon2D.new()
var polygon2 = Polygon2D.new()
var polygon3 = Polygon2D.new()

func _ready():
	polygon1.polygon = PackedVector2Array([Vector2(0, 0), Vector2(0, 50), Vector2(50, 50), Vector2(50, 0)])
	polygon2.polygon = PackedVector2Array([Vector2(0, 0), Vector2(0, -50), Vector2(50, -50), Vector2(50, 0)])
	print(polygon1.polygon, polygon2.polygon)
	polygon1.color = Color(0, 0.5, 0.5, 0.3)
	polygon2.color = Color(0.5, 0, 0.5, 0.3)
	add_child(polygon1)
	add_child(polygon2)
	
	var newPolyPV2A = Geometry2D.merge_polygons(polygon1.polygon, polygon2.polygon)
	print(newPolyPV2A, typeof(newPolyPV2A))
	polygon3.polygon = newPolyPV2A[0]
	print(polygon3.polygon)
	add_child(polygon3)
