extends Node2D

const tileSizeAdjustment = 15
const tileRef = {"ground": Vector2i(1, 1), "water": Vector2i(3, 1)}

var landOrSea = FastNoiseLite.new()
var start = Vector2(-20, -200)
var mapSize = Vector2(400, 400)

func setup_pathfinding(noise):
	for x in range(start.x, start.x+mapSize.x):
		for y in range(start.y, start.y+mapSize.y):
			var value = noise.get_noise_2d(x*tileSizeAdjustment, y*tileSizeAdjustment)
			var pos = Vector2i(x, y)
			setCell(pos, value)
	
	$Sand.setupBoundaryConditions()

func setCell(pos, value):
	if value > -0.03:
		$Sand.set_cell(0, pos, 0, tileRef["ground"])
	else:
		$Sand.set_cell(0, pos, 0, tileRef["water"])
