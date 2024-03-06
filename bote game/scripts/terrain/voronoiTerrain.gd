extends Node2D

const WATER = Color(0, 0.25, 0.35, 0.3)
const SAND = Color(0.3, 0.3, 0.1, 0.3)

var delaunay: Delaunay

func _ready():
	delaunay = Delaunay.new(Rect2(-50000, -20000, 50000, 20000))
	
	randomize()
	for i in range(-20, 20):
		for j in range(-10, 10):
			delaunay.add_point(Vector2(i*1000 + randi_range(-300,300), j*1000 + randi_range(-300,300)) * 1.2)
	
	var triangles = delaunay.triangulate()
	var regions = delaunay.make_voronoi(triangles)
	var heightMap = createNoise()
	
	var tiles = []
	
	for region in regions:
		var polygon = setupPolygon(region)
		var value = 2 * heightMap.get_noise_2dv(polygon.polygon[0]/80) + centralFocus(region.center)
		polygon.color = Color(value, value, value, 0.6) if value > 0 else WATER
		
		var newTile = Tile.new(region, polygon)
		if value < 0:
			newTile.isNavTile = true
		
		tiles.append(newTile)
		add_child(polygon)
	
	var navigablePolygon = NavigationPolygon.new()
	for tile in tiles:
		if tile.isNavTile:
			navigablePolygon.add_outline(tile.polygon.polygon)
	NavigationServer2D.bake_from_source_geometry_data(navigablePolygon, NavigationMeshSourceGeometryData2D.new());
	%navigableMap.navigation_polygon = navigablePolygon

class Tile:
	var region
	var polygon
	var isNavTile
	
	func _init(initRegion, initPolygon):
		self.region = initRegion
		self.polygon = initPolygon

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

func colourTiles(tiles):
	for tile in tiles:
		if not tile.isNavTile:
			for neighbour in tile.neighbours:
				if neighbour.isNavTile:
					tile.polygon.color = SAND

func centralFocus(point):
	return 0.5 - point.length()/13000

func setupPolygon(region: Delaunay.VoronoiSite):
	var polygon = Polygon2D.new()
	var p = region.polygon
	p.append(p[0])
	polygon.polygon = p
	polygon.z_index = -1
	
	return polygon

func showBorders(region: Delaunay.VoronoiSite):
	var line = Line2D.new()
	var p = region.polygon
	p.append(p[0])
	line.points = p
	line.width = 3
	line.default_color = Color.GREEN_YELLOW
	
	return line


"""extends Node2D

const WATER = Color(0.01400048937649, 0.25016698241234, 0.36195242404938, 0.30000001192093)
const SHALLOWS = Color(0.17935448884964, 0.34574511647224, 0.44956946372986, 0.32549020648003)

const tileMapNoiseAdjustment = 13
const tileRef = {"ground": Vector2i(1, 1), "water": Vector2i(3, 1)}
const voronoiTileSize = 1024
const noiseImpact = 25

var voronoiStart = Vector2(-25, -15)
var voronoiEnd = Vector2(25, 15)

var tileStart = Vector2(-50, -30)
var tileEnd = Vector2(50, 30)

var delaunay: Delaunay

func _ready():
	print("1 Initialising Delaunay")
	delaunay = Delaunay.new(Rect2(-50000, -20000, 50000, 20000))
	print("1 Completed")
	
	print("2 Setting up Delaunay Points")
	randomize()
	for i in range(voronoiStart.x, voronoiEnd.x):
		for j in range(voronoiStart.y, voronoiEnd.y):
			delaunay.add_point(Vector2(i*voronoiTileSize + randi_range(-300,300), j*voronoiTileSize + randi_range(-300,300)) * 1.2)
	print("2 Completed")
	
	print("3 Setting up Noise, Triangulation & Regions")
	var triangles = delaunay.triangulate()
	var regions = delaunay.make_voronoi(triangles)
	var heightMap = createNoise()
	print("3 Completed")
	
	print("4 Setting up Tiles")
	var tiles = []
	
	for region in regions:
		var newTile = setupTile(region, heightMap)
		tiles.append(newTile)
	
	for tile in tiles:
		for edge in tile.region.neighbours:
			for potentialNeighbour in tiles:
				if potentialNeighbour.region == edge.other:
					tile.neighbours.append(potentialNeighbour)
					break
	print("4 Completed")
	
	print("5 Setting up Pathfinding")
	setup_pathfinding(heightMap)
	print("Completed")

func setup_pathfinding(heightMap):
	var tileScaling = $pathfindingGen.scale.x / 64
	for x in range(tileStart.x-10, tileEnd.x+10):
		for y in range(tileStart.y-5, tileEnd.y+5):
			var value = heightMap.get_noise_2d(x*noiseImpact*tileScaling, y*noiseImpact*tileScaling)
			var pos = Vector2i(x, y)
			value += centralFocus(pos*tileScaling)
			setCell(pos, value+0.3)
	
	$pathfindingGen.setupBoundaryConditions()

func setupPathfinding(heightMap):
	for x in range(tileStart.x-10, tileEnd.x+10):
		for y in range(tileStart.y-5, tileEnd.y+5):
			
			var value = heightMap.get_noise_2d(x*noiseImpact, y*noiseImpact)
			var pos = Vector2i(x, y)
			value += centralFocus(pos)
			setCell(pos, value+0.3)
	
	$pathfindingGen.setupBoundaryConditions()

func setCell(pos, value):
	if value > -0.05:
		$pathfindingGen.set_cell(0, pos, 0, tileRef["ground"])
	else:
		$pathfindingGen.set_cell(0, pos, 0, tileRef["water"])

func centralFocus(point):
	return 0.5 - point.length()/20

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

func createNoise():
	var land = FastNoiseLite.new()
	land.seed = randi()
	land.noise_type = 4
	
	return land

func setupTile(region: Delaunay.VoronoiSite, heightMap):
	var polygon = Polygon2D.new()
	polygon.polygon = region.polygon
	polygon.polygon.append(polygon.polygon[0])
	polygon.z_index = -1
	
	var isNavTile = false
	var averagePoint = region.center
	var noisePosition = noiseImpact * averagePoint/voronoiTileSize
	var value = heightMap.get_noise_2dv(noisePosition) + centralFocus(averagePoint/voronoiTileSize)
	
	if value > 0:
		polygon.color = Color(value, value, value, 0.6)
	else:
		polygon.color = WATER
		isNavTile = true
	add_child(polygon)
	
	var newTile = Tile.new(region, polygon)
	newTile.isNavTile = isNavTile
	return Tile.new(region, polygon)

func showBorders(region: Delaunay.VoronoiSite):
	var line = Line2D.new()
	var p = region.polygon
	p.append(p[0])
	line.points = p
	line.width = 3
	line.default_color = Color.GREEN_YELLOW
	
	return line
"""
