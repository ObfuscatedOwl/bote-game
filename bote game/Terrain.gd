extends Node2D

var landOrSea = FastNoiseLite.new()
var start = Vector2(-100, -100)
var camSize = Vector2(1300, 800)

var points = PackedVector2Array()
var colours = PackedColorArray()

func _ready():
	landOrSea.seed = randi()
	
	for x in range(start.x, camSize.x):
		for y in range(start.y, camSize.y):
			var opacity = (landOrSea.get_noise_2d(x, y) + 1)/2
			points.append(Vector2(x, y))
			colours.append(Color(1, 1, 1, opacity))

func _draw():
	for i in range(len(points)):
		var point = PackedVector2Array([points[i]])
		var colour = PackedColorArray([colours[i]])
		draw_primitive(point, colour, PackedVector2Array())

func _process(delta):
	pass
