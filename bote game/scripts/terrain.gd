extends Node2D

const tileSizeAdjustment = 0.5
const tileRef = {"ground": Vector2i(1, 1), "water": Vector2i(3, 1)}

var landOrSea = FastNoiseLite.new()
var start = Vector2(-100, -100)
var camSize = Vector2(200, 200)

func _ready():
	landOrSea.noise_type = 1
	landOrSea.seed = randi()
	
	for x in range(start.x, start.x+camSize.x):
		for y in range(start.y, start.y+camSize.y):
			var value = landOrSea.get_noise_2d(x*tileSizeAdjustment, y*tileSizeAdjustment) * centralFocus(x, y)
			var pos = Vector2i(x, y)
			setCell(pos, value)
	
	$Map.setupBoundaryConditions()

func setCell(pos, value):
	if value < 0.1:
		$Map.set_cell(0, pos, 0, tileRef["water"])
	else:
		$Map.set_cell(0, pos, 0, tileRef["ground"])

func centralFocus(x, y):
	return pow(start.length() / (10 * Vector2(x, y).length() + 1), 1)
