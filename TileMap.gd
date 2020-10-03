extends TileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	var flat_game_board = []
	var idx = 0
	for y in range(64):  # TODO: 64 is too big, and also it's set somewhere else I think.
		for x in range(64):
			set_cell(x, y, idx)
			flat_game_board.append(null)
			idx+=1
	var maindude = $MainDude
	flat_game_board[0] = maindude

func get_obj_from_tile(int x, int y):
	# Returns null if there is nothing there, otherwise it
	# returns the thing that is in the tile.
	var cell = get_cell(map_pos[0], map_pos[1])
	if cell == -1:
		print("YOU CLICKED OUTSIDE THE MAP! NOT ALLOWED")
		return null
	else:
		var idx = 

func _input(event):
	if event.is_action_pressed("ui_left_click"):
		var map_pos = world_to_map(event.position)
		var cell = get_cell(map_pos[0], map_pos[1])
		print(cell)

		# CLicked on no cell (outside map?)
		if cell == -1:
			print("Clicked outside map - I hope.")
			return

		# TODO: Write else.
