extends TileMap

var flat_game_board
var flat_map
var number_of_steps_to

var X = 10
var Y = 10
var SIZE = X * Y
var current_enemy_idx = null

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

	# Just a helper array that I don't wanna reallocate all the time.
	number_of_steps_to = []

	var idx = 0
	for y in range(Y):  # TODO: Y is too small, and also it's set somewhere else I think.
		for x in range(X):
			set_cell(x, y, 0)
			flat_game_board.append(null)
			number_of_steps_to.append(false)
			flat_map.append(1)
			idx += 1

	# This is were the level is created.
	update_bitmask_region(Vector2(0, 0), Vector2(X, Y))

	var maindude = load("res://Character.tscn").instance()
	self.add_child(maindude)
	#var maindude = $MainDude
	flat_game_board[0] = maindude
"""
func get_next_enemy():
	# Returns the next enemy, or if all the enemies have been returned
	# then null is returned.
	var start_idx
	if current_enemy_idx == null:
		start_idx = 0
	else:
		start_idx = current_enemy_idx

	var idx = start_idx + 1
	while idx < SIZE:
		
	
	current_enemy_idx = null
	return null
	"""

func xy_to_flat(x, y):
	return y * X + x

func flat_to_xy(idx):
	idx = int(idx)
	var x = idx % X
	var y = int(idx) / Y
	return Vector2(x, y)

func get_all_possible_movement_destinations_rec_func(idx, current_number_of_steps, max_movement, the_lava_is_floor):
	if number_of_steps_to[idx] == null:
		number_of_steps_to[idx] = current_number_of_steps
	else:
		number_of_steps_to[idx] = min(number_of_steps_to[idx], current_number_of_steps)

	if current_number_of_steps >= max_movement:
		return

	# Up
	var idx_up = idx + X
	if idx_up < SIZE and (flat_map[idx_up] or the_lava_is_floor) and (number_of_steps_to[idx_up]==null or number_of_steps_to[idx_up] < current_number_of_steps):
		get_all_possible_movement_destinations_rec_func(idx_up, current_number_of_steps+1, max_movement, the_lava_is_floor)

	# Down
	var idx_down = idx - X
	if idx_down < SIZE and (flat_map[idx_down] or the_lava_is_floor) and (number_of_steps_to[idx_down]==null or number_of_steps_to[idx_down] < current_number_of_steps):
		get_all_possible_movement_destinations_rec_func(idx_down, current_number_of_steps+1, max_movement, the_lava_is_floor)

	# Left
	var idx_left = idx - 1
	if idx_left/X == idx/X and idx_left>0 and (flat_map[idx_left] or the_lava_is_floor) and (number_of_steps_to[idx_left]==null or number_of_steps_to[idx_left] < current_number_of_steps):
		get_all_possible_movement_destinations_rec_func(idx_left, current_number_of_steps+1, max_movement, the_lava_is_floor)

	# Right
	var idx_right = idx + 1
	if idx_right/X == idx/X and idx_right<SIZE and (flat_map[idx_right] or the_lava_is_floor) and (number_of_steps_to[idx_right]==null or number_of_steps_to[idx_right] < current_number_of_steps):
		get_all_possible_movement_destinations_rec_func(idx_right, current_number_of_steps+1, max_movement, the_lava_is_floor)

func get_all_possible_movement_destinations(idx, max_movement, the_lava_is_floor=false):
	for i in range(X*Y):
		number_of_steps_to[i] = null

	# Calculate all positions that can be reached. 
	get_all_possible_movement_destinations_rec_func(idx, 0, max_movement, the_lava_is_floor)

	# Convert to a more readable data format. 
	var destinations = []
	for idx in range(SIZE):
		if number_of_steps_to[idx] != null:
			var pos = flat_to_xy(idx)
			destinations.append(pos)
	return destinations

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
	if x < 0 or x >= X or y < 0 or y >= Y:
		print("YOU CLICKED OUTSIDE THE MAP! NOT ALLOWED")
		return null
	else:
		return flat_game_board[xy_to_flat(x, y)]

func _input(event):
	if event.is_action_pressed("ui_left_click"):
		var map_pos = world_to_map(event.position)
		
		var relevant_obj = get_obj_from_tile(map_pos[0], map_pos[1])
		if relevant_obj != null:
			relevant_obj.on_click(xy_to_flat(map_pos[0], map_pos[1]))

