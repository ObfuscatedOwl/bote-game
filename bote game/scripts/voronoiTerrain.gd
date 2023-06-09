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
	var polygons = []
	var land = createNoise()

	for region in regions:
		var polygon = setupPolygon(region, land)
		polygons.append(polygon)
		add_child(polygon)
	
	# var seaGroups = getSeaGroups(regions, polygons)

	# $voronoiNavRegion.navigation_polygon = setupNavPolygon(seaGroups)

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

func setupNavPolygon(polygons):
	var navPolygon = NavigationPolygon.new()

	for polygon in polygons:
		var navOutline = []
		for vertex in polygon.polygon:
			navOutline.append(vertex)
		
		var outline = PackedVector2Array(navOutline)
		navPolygon.add_outline(outline)
	
	navPolygon.make_polygons_from_outlines()
	return navPolygon

func createNoise():
	var land = FastNoiseLite.new()
	land.seed = randi()
	land.noise_type = 4
	return land

"""
func getSeaGroups(regions, polygons):
	var sites = []
	for i in range(len(regions)):
		if polygons[i].color == WATER:
			sites.append([regions[i], polygons[i]])
	
	var usedSites = []
	var seaGroups = []

	groupIndex = 0
	for site in sites:
		if site in usedSites:
			continue
		usedSites.append(site)
		seaGroups.append([site])

		var neighbours = getNeighbours(site, usedSites)
		usedSites += neighbours
		seaGroups[groupIndex] += neighbours

		while neighbours:
			var nextNeighbours = []
			for neighbour in neighbours:
				nextNeighbours += getNeighbours(neighbour, usedSites)
			
			usedSites += nextNeighbours
			seaGroups[groupIndex] += nextNeighbours
			neighbours = nextNeighbours
"""