extends Node

# NOTE: NEVER CHANGE ANYTHING IN THE flat_board VARIABLE, OKAY?
# 		IT IS READ-ONLY! OTHERWISE WE WILL HAVE THE MOST CONVOLUTED
#		AND UNSOLVABLE BUGS IMAGINABLE, OKAY? Good.

var sizex : int = -1
var sizey : int = -1

# These 2 variables are flat binary lists. That means that a tile
# is walkable if binary_mask[x + y * sizex] is true.
# The permanet_binary_mask is set at the start and never changed; it
# represents the map layout.
# The binary_mask is changed every turn. It is false if the permanent
# mask is false, or if an opponent is standing on the corresponding tile.
var binary_mask = []
var permanent_binary_mask = []
var binary_mask_good_guys = []

var number_of_steps_to = [] # TODO: Move to Character.

func setup(flat_map, _sizex, _sizey):
	# Copy size of the board
	sizex = _sizex
	sizey = _sizey
	
	for i in range(sizex*sizey):
		number_of_steps_to.append(null)
	
	# The binary mask is one 1 a tile is walkable, and 0 otherwise.
	for idx in range(len(flat_map)):
		binary_mask_good_guys.append(true)
		if flat_map[idx] != 0:
			permanent_binary_mask.append(true)
		else:
			permanent_binary_mask.append(false)
	binary_mask = [] + permanent_binary_mask
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
		var r = randi() % len(character["movements"])
		var chosen_move = character["movements"][r]  # TODO: Sometimes it chooses to move to the exact same spot, which should be treated the same as doing nothing.
		var old_x = character["x"]
		var old_y = character["y"]
		
		# Check that the chosen tile actually is empty.
		var new_x = chosen_move[0]
		var new_y = chosen_move[1]
		assert(new_x >= 0 and new_x < sizex)
		assert(new_y >= 0 and new_y < sizey)
		var new_idx = new_x * sizex + new_y
		if flat_board_copy[new_idx] == null:
			var old_idx = old_x * sizex + old_y
			flat_board_copy[new_idx] = flat_board_copy[old_idx]
			flat_board_copy[old_idx] = null
			
			var new_move = {"old_pos": [old_x, old_y], "new_pos": [new_x, new_y], "attacked_pos": null}
			all_chosen_moves.append(new_move)
	
	return all_chosen_moves

# TODO: This code is taken from TileMap. It shouldn't be there and it shouldn't be here. It should be in
# Character, but that file is currently under reconstruction. Will move there later.
func get_all_possible_movement_destinations_rec_func(idx, current_number_of_steps, max_movement, the_lava_is_floor):
	idx = int(idx)
	if number_of_steps_to[idx] == null:
		number_of_steps_to[idx] = current_number_of_steps
	else:
		number_of_steps_to[idx] = min(number_of_steps_to[idx], current_number_of_steps)

	if current_number_of_steps >= max_movement:
		return

	# Up
	var idx_up = idx + sizex
	if idx_up < sizex*sizey and (binary_mask[idx_up] or the_lava_is_floor) and (number_of_steps_to[idx_up]==null or number_of_steps_to[idx_up] > current_number_of_steps):
		get_all_possible_movement_destinations_rec_func(idx_up, current_number_of_steps+1, max_movement, the_lava_is_floor)

	# Down
	var idx_down = idx - sizex
	if idx_down >= 0 and (binary_mask[idx_down] or the_lava_is_floor) and (number_of_steps_to[idx_down]==null or number_of_steps_to[idx_down] > current_number_of_steps):
		get_all_possible_movement_destinations_rec_func(idx_down, current_number_of_steps+1, max_movement, the_lava_is_floor)

	# Left
	var idx_left = idx - 1
	if int(idx_left/sizex) == int(idx/sizex) and idx_left>0 and (binary_mask[idx_left] or the_lava_is_floor) and (number_of_steps_to[idx_left]==null or number_of_steps_to[idx_left] > current_number_of_steps):
		get_all_possible_movement_destinations_rec_func(idx_left, current_number_of_steps+1, max_movement, the_lava_is_floor)

	# Right
	var idx_right = idx + 1
	if int(idx_right/sizex) == int(idx/sizex) and idx_right<sizex*sizey and (binary_mask[idx_right] or the_lava_is_floor) and (number_of_steps_to[idx_right]==null or number_of_steps_to[idx_right] > current_number_of_steps):
		get_all_possible_movement_destinations_rec_func(idx_right, current_number_of_steps+1, max_movement, the_lava_is_floor)

# TODO: This code is taken from TileMap. It shouldn't be there and it shouldn't be here. It should be in
# Character, but that file is currently under reconstruction. Will move there later.
func get_all_possible_movement_destinations_rec_func_good(idx, current_number_of_steps, max_movement, the_lava_is_floor):
	idx = int(idx)
	if number_of_steps_to[idx] == null:
		number_of_steps_to[idx] = current_number_of_steps
	else:
		number_of_steps_to[idx] = min(number_of_steps_to[idx], current_number_of_steps)

	if current_number_of_steps >= max_movement:
		return

	# Up
	var idx_up = idx + sizex
	if idx_up < sizex*sizey and (binary_mask_good_guys[idx_up] or the_lava_is_floor) and (number_of_steps_to[idx_up]==null or number_of_steps_to[idx_up] > current_number_of_steps):
		get_all_possible_movement_destinations_rec_func_good(idx_up, current_number_of_steps+1, max_movement, the_lava_is_floor)

	# Down
	var idx_down = idx - sizex
	if idx_down >= 0 and (binary_mask_good_guys[idx_down] or the_lava_is_floor) and (number_of_steps_to[idx_down]==null or number_of_steps_to[idx_down] > current_number_of_steps):
		get_all_possible_movement_destinations_rec_func_good(idx_down, current_number_of_steps+1, max_movement, the_lava_is_floor)

	# Left
	var idx_left = idx - 1
	if int(idx_left/sizex) == int(idx/sizex) and idx_left>0 and (binary_mask_good_guys[idx_left] or the_lava_is_floor) and (number_of_steps_to[idx_left]==null or number_of_steps_to[idx_left] > current_number_of_steps):
		get_all_possible_movement_destinations_rec_func_good(idx_left, current_number_of_steps+1, max_movement, the_lava_is_floor)

	# Right
	var idx_right = idx + 1
	if int(idx_right/sizex) == int(idx/sizex) and idx_right<sizex*sizey and (binary_mask_good_guys[idx_right] or the_lava_is_floor) and (number_of_steps_to[idx_right]==null or number_of_steps_to[idx_right] > current_number_of_steps):
		get_all_possible_movement_destinations_rec_func_good(idx_right, current_number_of_steps+1, max_movement, the_lava_is_floor)


func get_all_possible_movement_destinations_good(idx, max_movement, the_lava_is_floor=false):
	for i in range(sizex*sizey):
		number_of_steps_to[i] = null

	# Calculate all positions that can be reached. 
	get_all_possible_movement_destinations_rec_func_good(idx, 0, max_movement, the_lava_is_floor)

	# Convert to a more readable data format. 
	var destinations = []
	for idx in range(sizex*sizey):
		if number_of_steps_to[idx] != null:
			var x = idx % sizex
			var y = int(idx / sizex)
			var pos = [x, y]
			destinations.append(pos)
	return destinations

func get_all_possible_movement_destinations(idx, max_movement, the_lava_is_floor=false):
	for i in range(sizex*sizey):
		number_of_steps_to[i] = null

	# Calculate all positions that can be reached. 
	get_all_possible_movement_destinations_rec_func(idx, 0, max_movement, the_lava_is_floor)

	# Convert to a more readable data format. 
	var destinations = []
	for idx in range(sizex*sizey):
		if number_of_steps_to[idx] != null:
			var x = idx % sizex
			var y = int(idx / sizex)
			var pos = [x, y]
			destinations.append(pos)
	return destinations

func get_all_possible_movements_of_character(character_dict, flat_board):
	var character = character_dict["character"]
	var x_pos = character_dict["x"]
	var y_pos = character_dict["y"]
	var idx = x_pos + sizex * y_pos
	var all_moves = get_all_possible_movement_destinations(idx, character.max_walk_distance, character.can_walk_on_lava)
	
	for i in range(len(all_moves)):
		assert(len(all_moves[i]) == 2)  # The x- and y-coordinates.
		#all_moves[i] = [all_moves[i][0] + x_pos, all_moves[i][1] + y_pos]

	# TODO: Remove at a later point. It's just for debugging.
	for i in range(len(all_moves)):
		var move = all_moves[i]
		var move_idx = move[0] + move[1] * sizex
		assert(move[0] >= 0 and move[0] < sizex and move[1] >= 0 and move[1] < sizey)
		assert(binary_mask[move_idx])
		assert(permanent_binary_mask[move_idx])
		#assert(flat_board[move_idx]==null or flat_board[move_idx].is_evul())  # These are filtered later
	return all_moves

func get_all_possible_movements_of_good_character(character_dict, flat_board):
	var character = character_dict["character"]
	var x_pos = character_dict["x"]
	var y_pos = character_dict["y"]
	var idx = x_pos + sizex * y_pos
	var all_moves = get_all_possible_movement_destinations_good(idx, character.max_walk_distance, character.can_walk_on_lava)
	
	for i in range(len(all_moves)):
		assert(len(all_moves[i]) == 2)  # The x- and y-coordinates.
		#all_moves[i] = [all_moves[i][0] + x_pos, all_moves[i][1] + y_pos]

	# TODO: Remove at a later point. It's just for debugging.
	for i in range(len(all_moves)):
		var move = all_moves[i]
		var move_idx = move[0] + move[1] * sizex
		assert(move[0] >= 0 and move[0] < sizex and move[1] >= 0 and move[1] < sizey)
		assert(binary_mask_good_guys[move_idx])
		assert(permanent_binary_mask[move_idx])
		#assert(flat_board[move_idx]==null or flat_board[move_idx].is_evul())  # These are filtered later
	return all_moves


func make_shadow_copy(character):
	var shadow
	var is_object = not character.is_good() and not character.is_evul()  # TODO: This is not correct.
	if is_object:
		shadow = {
			"is_good": character.is_good(),
			"is_evul": character.is_evul()
		}
	else:
		shadow = {
			"is_good": character.is_good(),
			"is_evul": character.is_evul(),
			"max_walk_distance": character.max_walk_distance,
			"damage": character.damage,
			"can_walk_on_lava": character.can_walk_on_lava,
			"current_hp": character.current_hp,
			"attack_coordinates": character.get_attack_coordinates()
		}
	return shadow

func get_flat_board_shadow_of_shadow(flat_board):
	var copy = [] + flat_board
	for i in range(len(flat_board)):
		if flat_board[i] != null:
			var shadow_of_shadow = {}
			for key in flat_board[i]:
				shadow_of_shadow[key] = flat_board[i][key]
			copy[i] = shadow_of_shadow
			#copy[i] = flat_board[i].duplicate(4)
	return copy

func get_flat_board_deep_copy(flat_board):
	var copy = [] + flat_board
	for i in range(len(flat_board)):
		if flat_board[i] != null:
			copy[i] = make_shadow_copy(flat_board[i])
			#copy[i] = flat_board[i].duplicate(4)
	return copy

func extract_good_guys(flat_board):
	var good_guys = []
	for i in range(sizex * sizey):
		if flat_board[i] and flat_board[i].is_good():
			assert(binary_mask[i])
			good_guys.append({"character": flat_board[i], "x": i % sizex, "y": int(i / sizex)})
	return good_guys

func extract_bad_guys(flat_board):
	var bad_guys = []
	for i in range(sizex * sizey):
		if flat_board[i] and flat_board[i].is_evul():
			assert(binary_mask[i])
			bad_guys.append({"character": flat_board[i], "x": i % sizex, "y": int(i / sizex)})
	return bad_guys

func update_binary_mask(flat_board):
	for y in range(sizey):
		for x in range(sizex):
			var idx = x + y * sizey
			if not permanent_binary_mask[idx] or (flat_board[idx] and flat_board[idx].is_good()):
				binary_mask[idx] = false
			else:
				binary_mask[idx] = true

func squareDistFromIdxs(idx1, idx2):
	var x1 = idx1 % sizex
	var x2 = idx2 % sizex
	
	var y1 = int(idx1 / sizex)
	var y2 = int(idx2 / sizex)
	
	return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)

func heuristic(flat_board):
	var total_number_of_hp_of_good_guys = 0
	var total_number_of_hp_of_bad_guys = 0
	var all_bad_guys_idx = []
	var all_good_guys_idx = []
	for i in range(sizex*sizey):
		var el = flat_board[i]
		if el != null:
			if el["is_evul"]:
				all_bad_guys_idx.append(i)
				total_number_of_hp_of_bad_guys += el["current_hp"]
				# TODO: Move closer to the good guys
			if el["is_good"]:
				total_number_of_hp_of_good_guys += el["current_hp"]
				all_good_guys_idx.append(i)
	var sum_of_recip_of_closest_square_dists = 0.0
	for idx in all_bad_guys_idx:
		var closest_yet = INF
		for good_idx in all_good_guys_idx:
			var dist_sq = squareDistFromIdxs(idx, good_idx)
			
			if dist_sq < closest_yet:
				closest_yet = dist_sq
		sum_of_recip_of_closest_square_dists += 1.0 / (closest_yet + 0.1)
	
	return total_number_of_hp_of_bad_guys - total_number_of_hp_of_good_guys + 0.000001 * sum_of_recip_of_closest_square_dists

func update_state_vec(state_vec, moves_per_char):
	assert(len(state_vec) == len(moves_per_char))
	for i in range(len(state_vec)):
		state_vec[i] += 1
		if state_vec[i] == moves_per_char[i]:
			state_vec[i] = 0
			if i == len(state_vec) - 1:
				return true
		else:
			return false
	return false

func update_moves_on_flat_board(state_vec, bad_guys, flat_board_orig, attack_state):
	# Creates a (copy of) flat_board using the moves in state_vec.
	var flat_board = get_flat_board_deep_copy(flat_board_orig)
	
	for i in range(len(state_vec)):
		var chosen_move = bad_guys[i]["movements"][state_vec[i]]
		var old_x = bad_guys[i]["x"]
		var old_y = bad_guys[i]["y"]
		
		# var new_x = old_x + chosen_move[0]
		# var new_y = old_y + chosen_move[1]
		var new_x = chosen_move[0]
		var new_y = chosen_move[1]
		var old_idx = old_x + old_y * sizex
		var new_idx = new_x + new_y * sizex
		
		assert(flat_board[old_idx] != null)
		if flat_board[new_idx] != null:
			# This means that an other character is blocking the destination,
			# which is an issue.
			# TODO: Reorder the characters, and see if that solves the issue?
			return null
		var obj = flat_board[old_idx]
		flat_board[new_idx] = obj
		flat_board[old_idx] = null
		
		# TODO: Attack!
		var attack_coordinates = [] + obj["attack_coordinates"]  # TODO: I don't think this copy is needed?
		var has_attacked = false
		for el in attack_coordinates:
			var attacked_idx = el[0]+new_x + (el[1] + new_y) * sizex
			if attacked_idx >= 0 and attacked_idx < sizex * sizey and flat_board[attacked_idx] != null and flat_board[attacked_idx]["is_good"] and flat_board[attacked_idx]["current_hp"] > 0:
				flat_board[attacked_idx]["current_hp"] -= min(obj["damage"], flat_board[attacked_idx]["current_hp"])
				assert(flat_board[attacked_idx]["current_hp"] >= 0)
				attack_state.append(attacked_idx)
				has_attacked = true
				break
		if not has_attacked:
			attack_state.append(null)
	
	return flat_board

func update_moves_on_flat_board_and_calc_heuristic(state_vec, bad_guys, flat_board_orig, attack_state):
	# Creates a (copy of) flat_board using the moves in state_vec.
	var flat_board = get_flat_board_deep_copy(flat_board_orig)
	
	for i in range(len(state_vec)):
		var chosen_move = bad_guys[i]["movements"][state_vec[i]]
		var old_x = bad_guys[i]["x"]
		var old_y = bad_guys[i]["y"]
		
		# var new_x = old_x + chosen_move[0]
		# var new_y = old_y + chosen_move[1]
		var new_x = chosen_move[0]
		var new_y = chosen_move[1]
		var old_idx = old_x + old_y * sizex
		var new_idx = new_x + new_y * sizex
		
		assert(flat_board[old_idx] != null)
		if flat_board[new_idx] != null:
			# This means that an other character is blocking the destination,
			# which is an issue.
			# TODO: Reorder the characters, and see if that solves the issue?
			return -INF
		var obj = flat_board[old_idx]
		flat_board[new_idx] = obj
		flat_board[old_idx] = null
		
		# TODO: Attack!
		var attack_coordinates = [] + obj["attack_coordinates"]  # TODO: I don't think this copy is needed?
		var has_attacked = false
		for el in attack_coordinates:
			var attacked_idx = el[0]+new_x + (el[1] + new_y) * sizex
			if attacked_idx >= 0 and attacked_idx < sizex * sizey and flat_board[attacked_idx] != null and flat_board[attacked_idx]["is_good"] and flat_board[attacked_idx]["current_hp"] > 0:
				flat_board[attacked_idx]["current_hp"] -= min(obj["damage"], flat_board[attacked_idx]["current_hp"])
				assert(flat_board[attacked_idx]["current_hp"] >= 0)
				attack_state.append(attacked_idx)
				has_attacked = true
				break
		if not has_attacked:
			attack_state.append(null)
	
	return heuristic(flat_board)

func update_moves_on_flat_board_and_calc_heuristic_from_mini(good_guys_state_vec, good_guys, flat_board_orig):
	# Creates a (copy of) flat_board using the moves in state_vec.
	var flat_board = get_flat_board_shadow_of_shadow(flat_board_orig)
	
	for i in range(len(good_guys_state_vec)):
		var chosen_move = good_guys[i]["movements"][good_guys_state_vec[i]]
		var old_x = good_guys[i]["x"]
		var old_y = good_guys[i]["y"]
		
		var new_x = chosen_move[0]
		var new_y = chosen_move[1]
		var old_idx = old_x + old_y * sizex
		var new_idx = new_x + new_y * sizex
		
		assert(flat_board[old_idx] != null)
		if flat_board[new_idx] != null:
			# This means that an other character is blocking the destination,
			# which is an issue.
			# TODO: Reorder the characters, and see if that solves the issue?
			return INF
		var obj = flat_board[old_idx]
		flat_board[new_idx] = obj
		flat_board[old_idx] = null
		
		# TODO: Attack!
		var attack_coordinates = [] + obj["attack_coordinates"]  # TODO: I don't think this copy is needed?
		var has_attacked = false
		for el in attack_coordinates:
			var attacked_idx = el[0]+new_x + (el[1] + new_y) * sizex
			if attacked_idx >= 0 and attacked_idx < sizex * sizey and flat_board[attacked_idx] != null and flat_board[attacked_idx]["is_evul"] and flat_board[attacked_idx]["current_hp"] > 0:
				flat_board[attacked_idx]["current_hp"] -= min(obj["damage"], flat_board[attacked_idx]["current_hp"])
				
				assert(flat_board[attacked_idx]["current_hp"] >= 0)
				has_attacked = true
				break

	return heuristic(flat_board)

func mini(state_vec, good_guys, bad_guys, flat_board, attack_state):
	var good_guy_state_vec = []
	var moves_per_char = []
	
	for idx in range(sizex*sizey):
		binary_mask_good_guys[idx] = permanent_binary_mask[idx]
	for bg in bad_guys:
		var bg_idx = bg["x"] + bg["y"] * sizex
		binary_mask_good_guys[bg_idx] = false
	
	for good_guy in good_guys:
		var movements = get_all_possible_movements_of_good_character(good_guy, flat_board)
		good_guy["movements"] = movements
	for i in range(len(good_guys)):
		good_guy_state_vec.append(0)
		moves_per_char.append(len(good_guys[i]["movements"]))
	
	# Go thru all moves that can be made and check what the heuristic thinks.
	# Return the one that the heuristisk function thinks is best.
	var best_state_val = INF
	var debug_counter = 0
	var is_done = false
	if len(good_guy_state_vec) > 0:
		while not is_done:
			debug_counter += 1
			var val = update_moves_on_flat_board_and_calc_heuristic_from_mini(good_guy_state_vec, good_guys, flat_board)
			# var val = mini(state_vec, bad_guys, flat_board, attack_state)
			if val <= best_state_val:
				best_state_val = val
			is_done = update_state_vec(good_guy_state_vec, moves_per_char)
			if debug_counter > 10000:
				push_error("consider_all_moves is stuck in a loop.")
	return best_state_val

func consider_all_moves(bad_guys, good_guys, flat_board):
	# TODO: Does not consider attacks. Fix?
	# TODO: I guess the order should matter to, but I don't wanna right now.
	# TODO: This just looks one step ahead, which is a bit stooopid.
	# TODO: Attack should be a part of the state.
	var state_vec = []
	var moves_per_char = []
	for i in range(len(bad_guys)):
		state_vec.append(0)
		moves_per_char.append(len(bad_guys[i]["movements"]))
	
	# Go thru all moves that can be made and check what the heuristic thinks.
	# Return the one that the heuristisk function thinks is best.
	var best_state = []
	var best_attack_state = []
	var best_state_val = -INF
	var debug_counter = 0
	var is_done = false
	if len(state_vec) > 0:
		while not is_done:
			var attack_state = []
			debug_counter += 1
			#var val = update_moves_on_flat_board_and_calc_heuristic(state_vec, bad_guys, flat_board, attack_state)
			var edited_flat_board = update_moves_on_flat_board(state_vec, bad_guys, flat_board, attack_state)
			if edited_flat_board != null:
				
				var val = mini(state_vec, good_guys, bad_guys, edited_flat_board, attack_state)
				if val >= best_state_val:
					best_state_val = val
					best_state = [] + state_vec
					best_attack_state = [] + attack_state
			is_done = update_state_vec(state_vec, moves_per_char)
			if debug_counter > 10000:
				push_error("consider_all_moves is stuck in a loop.")
		
	return convert_state_vec_to_interface(best_state, bad_guys, best_attack_state)

func convert_state_vec_to_interface(state_vec, bad_guys, attack_state):
	var all_chosen_moves = []
	assert(len(state_vec) == len(attack_state))
	for i in range(len(state_vec)):
		var r = state_vec[i]
		var chosen_move = bad_guys[i]["movements"][state_vec[i]]
		var old_x = bad_guys[i]["x"]
		var old_y = bad_guys[i]["y"]
		
		var new_x = chosen_move[0]
		var new_y = chosen_move[1]
		
		var attack_pos = null
		if attack_state[i]:
			attack_pos = [attack_state[i] % sizex, int(attack_state[i] / sizex)]
		
		var new_move = {"old_pos": [old_x, old_y], "new_pos": [new_x, new_y], "attacked_pos": attack_pos}
		all_chosen_moves.append(new_move)
	
	return all_chosen_moves

func get_moves(flat_board):
	# IMPORTANT: flat_board is read only. Don't change anything in it.
	assert(len(flat_board) == sizex * sizey)
	var bad_guys = extract_bad_guys(flat_board)
	var good_guys = extract_good_guys(flat_board)
	update_binary_mask(flat_board)
	
	for bad_guy in bad_guys:
		var movements = get_all_possible_movements_of_character(bad_guy, flat_board)
		bad_guy["movements"] = movements
	
	return consider_all_moves(bad_guys, good_guys, flat_board)
	# return get_random_moves(bad_guys, flat_board)
