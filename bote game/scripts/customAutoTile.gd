extends TileMap

const emptyCellID = Vector2i(3, 0)

var cells = []
var emptyCells = []

func setupBoundaryConditions():
	cells = get_used_cells(0)
	
	for cell in cells:
		if not allNeighboursSame(cell):
			emptyCells.append(cell)
			set_cell(0, cell, 0, emptyCellID)
	
	for cell in emptyCells:
		setCornerGroundCell(cell)
	
	for cell in emptyCells:
		if get_cell_atlas_coords(0, cell) == emptyCellID:
			set_cell(0, cell, 0, Vector2i(3, 1))

func allNeighboursSame(cell):
	for relativeX in [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)]:
		for relativeY in [Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1)]:
			if not get_cell_atlas_coords(0, cell) == get_cell_atlas_coords(0, cell + relativeX + relativeY):
				if not get_cell_atlas_coords(0, cell + relativeX + relativeY) == emptyCellID:
					return false
	return true

func setCornerGroundCell(cell):
	var groundCellCount = 0
	var cornerCellType = Vector2i(1, 1)
	
	for adjacent in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		if get_cell_atlas_coords(0, cell + adjacent) == Vector2i(1, 1):
			cornerCellType -= adjacent
			groundCellCount += 1
	
	if groundCellCount == 2:
		set_cell(0, cell, 0, cornerCellType)
