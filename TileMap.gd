extends TileMap

var flat_game_board

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# This is the list that contains all the THINGS that are on the board.
	# Note that there can only be one THING per tile. So an object and a player
	# can't be on the same tile (although the should be able to temporarily, but
	# then the player grabs the object I guess?) and a player and an enem can't
	# be on the same tiel either.
	flat_game_board = []
	
	var idx = 0
	for y in range(64):  # TODO: 64 is too big, and also it's set somewhere else I think.
		for x in range(64):
			set_cell(x, y, idx)
			flat_game_board.append(null)
			idx += 1
			
	# This is were the level is created.
	var maindude = $MainDude
	flat_game_board[0] = maindude

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
