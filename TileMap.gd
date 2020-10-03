extends TileMap

var flat_game_board
var flat_map

var X = 10
var Y = 10

# var MAX_MOVEMENT = 10  # For performance reasons

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# This is the list that contains all the THINGS that are on the board.
	# Note that there can only be one THING per tile. So an object and a player
	# can't be on the same tile (although the should be able to temporarily, but
	# then the player grabs the object I guess?) and a player and an enem can't
	# be on the same tile either.
	flat_game_board = []
	
	# The map is a boolean representation of the terrain.
	# 0 means that one can't go there, 1 means that one can. 
	flat_map = []
	var idx = 0
	for y in range(Y):  # TODO: Y is too small, and also it's set somewhere else I think.
		for x in range(X):
			set_cell(x, y, idx)
			flat_game_board.append(null)
			flat_map.append(0)
			idx += 1
			
	# This is were the level is created.
	var maindude = $MainDude
	flat_game_board[0] = maindude

	flat_map[0] = 1
	flat_map[1] = 1
	flat_map[2] = 1

func xy_to_flat(x, y):
	return y * X + x

func flat_to_xy(idx):
	var x = idx % X
	var y = int(idx) / Y
	return Vector2(x, y)

func get_movement(startX, startY, endX, endY):
	# Returns a Curve2D that goes from the start position
	# to the end position..

	var endIdx = xy_to_flat(endX, endY)
	if(flat_map[endIdx] == 0):
		push_error("MOVING TO TERRAIN THAT IS NOT ALLOWED!")
	# TODO: ADD SOME SORT OF A* ALGO, cause this is stooopid and weird and stuff.

	var path = Curve2D
	# TODO: SPAGETTI CODE!
	if startX != endX:
		var should_go_left = startX < endX
		if should_go_left:
			for x in range(startX, endX+1):
				var world_pos = map_to_world(Vector2(x, startY))
				path.add_point(world_pos)
		else:
			for x in range(endX, startX+1):
				var world_pos = map_to_world(Vector2(x, startY))
				path.add_point(world_pos)

	if startY != endY:
		var should_go_up = startY < endY
		if should_go_up:
			for y in range(startY, endY+1):
				var world_pos = map_to_world(Vector2(endX, y))
				path.add_point(world_pos)
		else:
			for y in range(endY, startY+1):
				var world_pos = map_to_world(Vector2(endX, y))
				path.add_point(world_pos)
	return path

func get_obj_from_tile(x, y):
	# Returns null if there is nothing there, otherwise it
	# returns the thing that is in the tile.
	var idx = get_cell(x, y)
	if idx == -1:
		print("YOU CLICKED OUTSIDE THE MAP! NOT ALLOWED")
		return null
	else:
		return flat_game_board[idx]

func _input(event):
	if event.is_action_pressed("ui_left_click"):
		var map_pos = world_to_map(event.position)
		
		var relevant_obj = get_obj_from_tile(map_pos[0], map_pos[1])
		if relevant_obj != null:
			relevant_obj.on_click()
