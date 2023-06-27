extends Node2D

var delaunay: Delaunay

func _ready():
	delaunay = Delaunay.new(Rect2(-50000, -20000, 50000, 20000))
	
	randomize()
	for i in range(-20, 20):
		for j in range(-10, 10):
			delaunay.add_point(Vector2(i*1000 + randi_range(-300,300), j*1000 + randi_range(-300,300)) * 1.2)

	var triangles = delaunay.triangulate()
	var regions = delaunay.make_voronoi(triangles)
	var land = createNoise()

	for region in regions:
		showRegion(region, land)

func showRegion(region: Delaunay.VoronoiSite, land):
	var polygon = setupPolygon(region)
	print(land.get_noise_2dv(polygon.polygon[0]))
	var value = 0 if land.get_noise_2dv(polygon.polygon[0]/100) > 0 else 1
	polygon.color = Color(value, value, value)
	add_child(polygon)

func createNoise():
	var land = FastNoiseLite.new()
	land.seed = randi()
	land.noise_type = 4
	return land

func setupPolygon(region: Delaunay.VoronoiSite):
	var polygon = Polygon2D.new()
	var p = region.polygon
	p.append(p[0])
	polygon.polygon = p
	polygon.z_index = -1
	return polygon
