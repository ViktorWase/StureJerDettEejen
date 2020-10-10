extends Node

# NOTE: NEVER CHANGE ANYTHING IN THE flat_board VARIABLE, OKAY?
# 		IT IS READ-ONLY! OTHERWISE WE WILL HAVE THE MOST CONVOLUTED
#		AND UNSOLVABLE BUGS IMAGINABLE, OKAY? Good.

var sizex : int = -1
var sizey : int = -1
var binary_mask = []

func setup(_binary_mask, _sizex, _sizey):
	# Copy size of the board
	sizex = _sizex
	sizey = _sizey
	
	# The binary mask is one 1 a tile is walkable, and 0 otherwise.
	binary_mask = [] + _binary_mask  # Bit of a hack, but it copies the data.
	assert(len(binary_mask) == sizex * sizey)

func get_all_possible_movements_from_length(move_length):
	# TODO: This assumes that we can just pass thru the good guys! Or walk on lava.
	# Honestly, this will need to be rewritten from scratch.
	
	# Sorry about this one, but I reckon that it'll be a total bottleneck so
	# it's optimized for speed
	var possible_moves
	if move_length == 0:
		possible_moves = [[0, 0]]
	elif move_length == 1:
		possible_moves = [[0, 0], [-1, 0], [1, 0], [0, 1], [0, -1]]
	elif move_length == 2:
		possible_moves = [[0, 0], [-1, 0], [1, 0], [0, 1], [0, -1], [-1, 1], [1, 1], [1, -1], [-1, -1], [-2, 0], [2, 0], [0, 2], [0, -2]]
	else:
		push_error("The algorithm in get_all_possible_movements_from_length hasn't been implemented fully yet.")
	
	return possible_moves

func get_random_moves(chars, flat_board):
	# This function is only used for debugging.
	# So far it doesn't even do attacks.
	var flat_board_copy = get_flat_board_deep_copy(flat_board)
	
	var all_chosen_moves = []
	
	# TODO: Shuffle the chars?
	for character in chars:
		var r = randi()%len(character["movements"])
		var chosen_move = character["movements"][r]  # TODO: Sometimes it chooses to move to the exact same spot, which should be treated the same as doing nothing.
		var old_x = character["x"]
		var old_y = character["y"]
		
		# Check that the chosen tile actually is empty.
		var new_x = old_x + chosen_move[0]
		var new_y = old_y + chosen_move[1]
		assert(new_x >=0 and new_x < sizex)
		assert(new_y >=0 and new_y < sizey)
		var new_idx = new_x * sizex + new_y
		if flat_board_copy[new_idx] == null:
			var old_idx = old_x * sizex + old_y
			flat_board_copy[new_idx] = flat_board_copy[old_idx]
			flat_board_copy[old_idx] = null
			
			var new_move = {"old_pos": [old_x, old_y], "new_pos": [new_x, new_y], "attacked_pos": null}
			all_chosen_moves.append(new_move)
	
	return all_chosen_moves

func get_all_possible_movements_of_character(character_dict, flat_board):
	var character = character_dict["character"]
	var x_pos = character_dict["x"]
	var y_pos = character_dict["y"]
	var all_moves = get_all_possible_movements_from_length(character.max_walk_distance)
	for i in range(len(all_moves)):
		assert(len(all_moves[i]) == 2)  # The x- and y-coordinates.
		all_moves[i] = [all_moves[i][0] + x_pos, all_moves[i][1] + y_pos]

	# Remove all moves that end up on a good guy or on a non-walkable tile.
	# Note that we keep moves that end up on other bad guys since that fellow
	# might have moved before this fellow moves.
	# TODO: Most of this should probably be up in get_all_possible_movements_from_length?
	var idx = 0
	while idx < len(all_moves):
		var move = all_moves[idx]
		var move_idx = move[0] + move[1] * sizex
		var is_forbidden = move[0] < 0 or move[0] >= sizex
		is_forbidden = is_forbidden or move[0] < 1 or move[1] >= sizey
		is_forbidden = is_forbidden or !binary_mask[move_idx] or (flat_board[idx] and flat_board[idx].is_good())
		if is_forbidden:
			all_moves.remove(idx)
		else:
			idx += 1
	
	return all_moves

func get_flat_board_deep_copy(flat_board):
	var copy = []
	for el in flat_board:
		if el == null:
			copy.append(null)
		else:
			copy.append(el.duplicate())
	return copy

func extract_bad_guys(flat_board):
	var bad_guys = []
	for i in range(sizex * sizey):
		if flat_board[i] and flat_board[i].is_evul():
			assert(binary_mask[i])
			bad_guys.append({"character": flat_board[i], "x": i % sizex, "y": int(i / sizex)})
	return bad_guys

func get_moves(flat_board):
	# IMPORTANT: flat_board is read only. Don't change anything in it.
	assert(len(flat_board) == sizex * sizey)
	var bad_guys = extract_bad_guys(flat_board)
	
	for bad_guy in bad_guys:
		var movements = get_all_possible_movements_of_character(bad_guy, flat_board)
		bad_guy["movements"] = movements
	
	return get_random_moves(bad_guys, flat_board)
