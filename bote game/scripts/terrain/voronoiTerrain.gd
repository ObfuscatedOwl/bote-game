extends Node2D

const WATER = Color(0, 0.25, 0.35, 0.3)

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
	
	var tiles = []
	
	for region in regions:
		var polygon = setupPolygon(region, land)
		var newTile = tile.new(region, polygon)
		tiles.append(newTile)
		add_child(polygon)
	
	for tile in tiles:
		for edge in tile.region.neighbours:
			for potentialNeighbour in tiles:
				if potentialNeighbour.region == edge.other:
					tile.neighbours.append(potentialNeighbour)
	
	var groupedNavPolygons = groupWaterNavRegions(tiles)
	for group in groupedNavPolygons:
		var combinedGroup = group[0]
		for polygon in group:
			combinedGroup.polygon = Geometry2D.merge_polygons(combinedGroup.polygon, polygon.polygon)
		add_child(setupNavRegion(combinedGroup))

class tile:
	var region
	var polygon
	var neighbours
	var isNavTile
	var matched
	
	func _init(region, polygon):
		self.region = region
		self.polygon = polygon
		
		self.neighbours = [] # Populate externally
		
		self.isNavTile = polygon.color == WATER
		self.matched = false

	func getPolyNavNeighbours() -> Array:
		for neighbour in self.neighbours:
			if not neighbour.matched and neighbour.isNavTile:
				self.matched = true
				var nextNeighbours = neighbour.getPolyNavNeighbours()
				return [self.polygon] + nextNeighbours
		return [self.polygon]

func groupWaterNavRegions(tiles):
	var groupedNavPolygons = []
	for tile in tiles:
		if not tile.matched:
			groupedNavPolygons.append(tile.getPolyNavNeighbours())
	
	return groupedNavPolygons

func setupNavRegion(polygon: Polygon2D):
	var navRegion = NavigationRegion2D.new()
	var navPolygon = NavigationPolygon.new()
	
	navPolygon.add_outline(polygon.polygon)
	navPolygon.make_polygons_from_outlines()
	navRegion.navigation_polygon = navPolygon
	
	return navRegion

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
	polygon.color = WATER if value > 0 else Color(value, value, value)

	return polygon

func showBorders(region: Delaunay.VoronoiSite):
	var line = Line2D.new()
	var p = region.polygon
	p.append(p[0])
	line.points = p
	line.width = 3
	line.default_color = Color.GREEN_YELLOW
	
	return line
