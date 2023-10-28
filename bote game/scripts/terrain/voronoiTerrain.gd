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
	var navTiles = []
	
	for region in regions:
		var polygon = setupPolygon(region, land)
		var newTile = Tile.new(region, polygon)
		if polygon.color == WATER:
			navTiles.append(newTile)
		tiles.append(newTile)
		add_child(polygon)
	
	print(len(navTiles))
	for tile in tiles:
		for edge in tile.region.neighbours:
			for potentialNeighbour in tiles:
				if potentialNeighbour.region == edge.other:
					tile.neighbours.append(potentialNeighbour)
	
	var groupedNavTiles = groupWaterNavRegions(navTiles)
	for group in groupedNavTiles:
		var combinedGroup = group[0].polygon.duplicate()
		for tile in group:
			var PV2Apolygon = tile.polygon.polygon
			combinedGroup.polygon = Geometry2D.merge_polygons(combinedGroup.polygon, PV2Apolygon)[0]
		add_child(setupNavRegion(combinedGroup))

class Tile:
	var region
	var polygon
	var neighbours
	var isNavTile
	
	func _init(region, polygon):
		self.region = region
		self.polygon = polygon
		
		self.neighbours = [] # Populate externally
		self.isNavTile = polygon.color == WATER

func groupWaterNavRegions(navTiles: Array):
	var allGroups = []
	while len(navTiles):
		print("new group")
		var newGroup = getNavNeighbours(navTiles[0])
		allGroups.append(newGroup)
		
		for navTile in newGroup:
			navTiles.erase(navTile)
	
	return allGroups

func getNavNeighbours(startingTile: Tile):
	var navGroup = [startingTile]
	var complete = false
	
	while not complete:
		complete = true
		for tile in navGroup:
			for neighbour in tile.neighbours:
				if not neighbour in navGroup and neighbour.isNavTile:
					complete = false
					navGroup.append(neighbour)
	
	return navGroup

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
	polygon.color = Color(value, value, value, 0.6) if value > 0 else WATER
	
	return polygon

func showBorders(region: Delaunay.VoronoiSite):
	var line = Line2D.new()
	var p = region.polygon
	p.append(p[0])
	line.points = p
	line.width = 3
	line.default_color = Color.GREEN_YELLOW
	
	return line
