extends Node2D

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
	delaunay = Delaunay.new(Rect2(-50000, -20000, 50000, 20000))
	
	randomize()
	for i in range(voronoiStart.x, voronoiEnd.x):
		for j in range(voronoiStart.y, voronoiEnd.y):
			delaunay.add_point(Vector2(i*voronoiTileSize + randi_range(-300,300), j*voronoiTileSize + randi_range(-300,300)) * 1.2)
	
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
	
	setup_pathfinding(heightMap)

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

func setupPolygon(region: Delaunay.VoronoiSite, heightMap):
	var polygon = Polygon2D.new()
	var p = region.polygon
	p.append(p[0])
	polygon.polygon = p
	polygon.z_index = -1
	
	var averagePoint = region.center
	
	var noisePosition = noiseImpact * averagePoint/voronoiTileSize
	var value = heightMap.get_noise_2dv(noisePosition) + centralFocus(averagePoint/voronoiTileSize)
	polygon.color = Color(value, value, value, 0.6) if value > 0 else WATER
	"""
	if (value > -0.2 and polygon.color == WATER):
		polygon.color = SHALLOWS
	"""
	return polygon

func showBorders(region: Delaunay.VoronoiSite):
	var line = Line2D.new()
	var p = region.polygon
	p.append(p[0])
	line.points = p
	line.width = 3
	line.default_color = Color.GREEN_YELLOW
	
	return line
