extends Node2D

const WATER = Color(0, 0.25, 0.35, 0.3)
const SAND = Color(0.3, 0.3, 0.1, 0.3)

const tileMapNoiseAdjustment = 13
const tileRef = {"ground": Vector2i(1, 1), "water": Vector2i(3, 1)}
const tileSize = 1024
const noiseImpact = 25

var start = Vector2(-20, -10)
var end = Vector2(20, 10)

var delaunay: Delaunay

func _ready():
	delaunay = Delaunay.new(Rect2(-50000, -20000, 50000, 20000))
	
	randomize()
	for i in range(start.x, end.x):
		for j in range(start.y, end.y):
			delaunay.add_point(Vector2(i*tileSize + randi_range(-300,300), j*tileSize + randi_range(-300,300)) * 1.2)
	
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
	for x in range(start.x-10, end.x+10):
		for y in range(start.y-5, end.y+5):
			var value = heightMap.get_noise_2d(x*noiseImpact, y*noiseImpact)
			var pos = Vector2i(x, y)
			value += centralFocus(pos)
			setCell(pos, value+0.05)
	
	$pathfindingGen.setupBoundaryConditions()

func setCell(pos, value):
	if value > -0.03:
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
	
	var averagePoint = Vector2.ZERO
	for vertex in polygon.polygon:
		averagePoint += vertex
	averagePoint /= len(polygon.polygon)
	
	var noisePosition = noiseImpact * averagePoint/tileSize
	var value = heightMap.get_noise_2dv(noisePosition) + centralFocus(averagePoint/tileSize)
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
