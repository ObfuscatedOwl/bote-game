extends Node2D

const WATER = Color(0, 0.25, 0.35, 0.3)
const SAND = Color(0.3, 0.3, 0.1, 0.3)

var start = Vector2(-20, -10)
var end = Vector2(20, 10)

var delaunay: Delaunay

func _ready():
	delaunay = Delaunay.new(Rect2(-50000, -20000, 50000, 20000))
	
	randomize()
	for i in range(start.x, end.x):
		for j in range(start.y, end.y):
			delaunay.add_point(Vector2(i*1000 + randi_range(-300,300), j*1000 + randi_range(-300,300)) * 1.2)
	
	var triangles = delaunay.triangulate()
	var regions = delaunay.make_voronoi(triangles)
	var heightMap = createNoise()
	
	var tiles = []
	var navTiles = []
	
	for region in regions:
		var polygon = setupPolygon(region, heightMap)
		var newTile = Tile.new(region, polygon)
		if polygon.color == WATER:
			newTile.isNavTile = true
			navTiles.append(newTile)
		add_child(polygon)
		tiles.append(newTile)
	
	for tile in tiles:
		for edge in tile.region.neighbours:
			for potentialNeighbour in tiles:
				if potentialNeighbour.region == edge.other:
					tile.neighbours.append(potentialNeighbour)
					break
	
	$"pathfindingGen".setup_pathfinding(heightMap)
	
	"""
	var groupedNavTiles = groupWaterNavRegions(navTiles)
	for group in groupedNavTiles:
		var combinedGroup = group[0].polygon.duplicate()
		for tile in group:
			var PV2Apolygon = tile.polygon.polygon
			combinedGroup.polygon = Geometry2D.merge_polygons(combinedGroup.polygon, PV2Apolygon)[0]
		print(combinedGroup, pow(len(combinedGroup.polygon), 2)/36)
		combinedGroup.color = WATER
		add_child(setupNavRegion(combinedGroup))
		add_child(combinedGroup)
	"""
	"""
	var potentialNeighbours = navTiles
	var allGroups = []
	
	var totalAreaPolygon = Polygon2D.new()
	totalAreaPolygon.polygon = PackedVector2Array([Vector2(-60000, -30000), Vector2(-60000, 30000), Vector2(60000, 30000), Vector2(60000, -30000)])
	
	for tile in tiles:
		if not tile.isNavTile:
			totalAreaPolygon.polygon = Geometry2D.clip_polygons(totalAreaPolygon.polygon, tile.polygon.polygon)[0]
			break
	
	print(len(totalAreaPolygon.polygon))
	totalAreaPolygon.color = WATER
	add_child(totalAreaPolygon)
	add_child(setupNavRegion(totalAreaPolygon))
	"""
	"""
	while potentialNeighbours:
		var groupCompleted = false
		var combinedGroup = potentialNeighbours[0].polygon
		potentialNeighbours.pop_front()
		
		while not groupCompleted:
			groupCompleted = true
			for tile in potentialNeighbours:
				var combination = Geometry2D.merge_polygons(combinedGroup.polygon, tile.polygon.polygon)[0]
				if combination:
					potentialNeighbours.erase(tile)
					groupCompleted = false
		
		combinedGroup.color = WATER
		add_child(setupNavRegion(combinedGroup))
		add_child(combinedGroup)
	"""

func centralFocus(x, y):
	return
	#return pow(start.length() / (10 * Vector2(x, y).length() + 1), 1)

class Tile:
	var region
	var polygon
	var neighbours
	var isNavTile
	
	func _init(initRegion, initPolygon):
		self.region = initRegion
		self.polygon = initPolygon
		
		self.neighbours = [] # Populated externally
		self.isNavTile = false

func groupWaterNavRegions(navTiles: Array):
	var allGroups = []
	while len(navTiles):
		var newGroup = getNavNeighbours(navTiles[0])
		allGroups.append(newGroup)
		
		for navTile in newGroup:
			navTiles.erase(navTile)
		
		print(len(navTiles))
	
	print(allGroups)
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
	navRegion.constrain_avoidance = true
	
	return navRegion

func createNoise():
	var land = FastNoiseLite.new()
	land.seed = randi()
	land.noise_type = 4
	
	return land

func colourTiles(tiles):
	for tile in tiles:
		if not tile.isNavTile:
			for neighbour in tile.neighbours:
				if neighbour.isNavTile:
					tile.polygon.color = SAND

func setupPolygon(region: Delaunay.VoronoiSite, heightMap):
	var polygon = Polygon2D.new()
	var p = region.polygon
	p.append(p[0])
	polygon.polygon = p
	polygon.z_index = -1
	
	var averagePoint = Vector2.ZERO
	for vertex in polygon.polygon:
		averagePoint += vertex
	averagePoint /= len(polygon.polygon)
	
	var value = heightMap.get_noise_2dv(polygon.polygon[0]/80)
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
