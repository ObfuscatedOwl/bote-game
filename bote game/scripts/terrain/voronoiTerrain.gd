extends Node2D

const WATER = Color(0, 0.25, 0.35, 0.3)

var delaunay: Delaunay

func _ready():
	print("hello????")
	delaunay = Delaunay.new(Rect2(-50000, -20000, 50000, 20000))
	
	randomize()
	for i in range(-20, 20):
		for j in range(-10, 10):
			delaunay.add_point(Vector2(i*1000 + randi_range(-300,300), j*1000 + randi_range(-300,300)) * 1.2)

	var triangles = delaunay.triangulate()
	var regions = delaunay.make_voronoi(triangles)
	
	var land = createNoise()
	var regionPolygon = {}
	var polygonNeighbours = {}

	for region in regions:
		var polygon = setupPolygon(region, land)
		add_child(polygon)

		if (polygon.color == WATER):
			regionPolygon[region] = polygon
	
	for region in regionPolygon:
		var neighbours = []
		for edge in region.neighbours:
			if edge.other in regionPolygon.keys():
				neighbours.append(regionPolygon[edge.other])
		polygonNeighbours[regionPolygon[region]] = neighbours
	
	var polygons = combineWater(polygonNeighbours)
	for polygon in polygons:
		var navRegion = setupNavRegion(polygon)
		add_child(navRegion)

		

func setupNavRegion(polygon: Polygon2D):
	var navRegion = NavigationRegion2D.new()
	var navPolygon = NavigationPolygon.new()

	navPolygon.add_outline(polygon.polygon)
	navPolygon.make_polygons_from_outlines()
	navRegion.navigation_polygon = navPolygon

	return navRegion

func combineWater(polygonNeighbours: Dictionary):
	print("how many")
	var size = polygonNeighbours.size()

	var target = null
	for polygon in polygonNeighbours:
		if (polygonNeighbours[polygon] > []):
			target = polygon
			continue
	if not target:
		return polygonNeighbours
	
	var newNeighbours = []
	var oldNeighbours = []

	for oldNeighbour in polygonNeighbours[target]:
		target.polygon = Geometry2D.merge_polygons(target.polygon, oldNeighbour.polygon)[0]
		oldNeighbours.append(oldNeighbour)
	
	for oldNeighbour in oldNeighbours:
		for newNeighbour in polygonNeighbours[oldNeighbour]:
			if not (target == newNeighbour or newNeighbour in oldNeighbours):
				newNeighbours.append(newNeighbour)

	newNeighbours = arrayUnique(newNeighbours)
	polygonNeighbours[target] = []
	
	for newNeighbour in newNeighbours:
		for oldNeighbour in oldNeighbours:
			if polygonNeighbours[newNeighbour].has(oldNeighbour):
				polygonNeighbours[newNeighbour].erase(oldNeighbour)
		
		polygonNeighbours[newNeighbour].append(target)
		polygonNeighbours[target].append(newNeighbour)
	
	for oldNeighbour in oldNeighbours:
		polygonNeighbours.erase(oldNeighbour)

	return combineWater(polygonNeighbours)

func arrayUnique(array: Array):
	var unique = []
	for item in array:
		if not unique.has(item):
			unique.append(item)
	return unique

func createNoise():
	var land = FastNoiseLite.new()
	land.seed = randi()
	land.noise_type = 4

	return land

func setupPolygon(region: Delaunay.VoronoiSite, land):
	var polygon = Polygon2D.new()
	var p = region.polygon
	p.append(p[0])
	polygon.polygon = p
	polygon.z_index = -1

	var value = land.get_noise_2dv(polygon.polygon[0]/80)
	var color = value if value > 0 else 1

	if color == 1:
		polygon.color = WATER
	else:
		polygon.color = Color(color, color, color)

	return polygon

func showLine(region: Delaunay.VoronoiSite):
	var line = Line2D.new()
	var p = region.polygon
	p.append(p[0])
	line.points = p
	line.width = 3
	line.default_color = Color.GREEN_YELLOW
	
	return line