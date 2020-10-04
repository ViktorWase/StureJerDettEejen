extends TileMap

var flat_game_board
var flat_map
var number_of_steps_to
var active_greens = []

var X = 10
var Y = 10
var SIZE = X * Y
var current_enemy_idx = null
var active_character
var resetting_characters = []
var number_of_turns_till_apocalypse = 12

enum game_states {
	player_turn,
	enemy_turn,
	DEATH_DESTRUCTION_AND_THE_APOCALYPSE,
	winning
}

enum game_turn_states {
	choose_character,
	select_tile,
	character_moving,
	select_attack,
	character_attacking,
	end_turn
}

var game_state = game_states.player_turn
var game_turn_state = game_turn_states.choose_character

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
	
	# Read data from scene
	var cells = get_used_cells()
	var maxX = 0
	var maxY = 0
	for cell in cells:
		if (cell.x > maxX):
			maxX = cell.x
		if (cell.y > maxY):
			maxY = cell.x
	X = int(maxX)
	Y = int(maxY)
	SIZE = X * Y

	#var idx = 0
	for y in range(Y):  # TODO: Y is too small, and also it's set somewhere else I think.
		for x in range(X):
			flat_game_board.append(null)
			number_of_steps_to.append(false)
			flat_map.append(0)
	
	# populate flat map
	for cell in cells:
		var i = xy_to_flat(cell.x, cell.y)
		flat_map[i] = 1

	# This is were the level is created.
	update_bitmask_region(Vector2(0, 0), Vector2(X, Y))
	
	for character in get_tree().get_nodes_in_group("Characters"):
		var charX = floor(character.position.x / 32)
		var charY = floor(character.position.y / 32)
		var i = xy_to_flat(charX, charY)
		flat_game_board[i] = character
		character.set_start_coordinates(Vector2(charX, charY))
	
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		var charX = floor(enemy.position.x / 32)
		var charY = floor(enemy.position.y / 32)
		var i = xy_to_flat(charX, charY)
		flat_game_board[i] = enemy
		enemy.set_start_coordinates(Vector2(charX, charY))
	
	var rocket = $Rocket
	var charX = floor(rocket.position.x / 32)
	var charY = floor(rocket.position.y / 32)
	var i = xy_to_flat(charX, charY)
	flat_game_board[i] = rocket
	rocket.set_coordinates(Vector2(charX, charY))

	var plane = load("res://Character.tscn").instance()  # TODO: The plane really looks like a dude.
	plane.object_type = 'plane'
	flat_game_board[xy_to_flat(9, 2)] = plane
	self.add_child(plane)
	plane.set_neutral()
	plane.set_start_coordinates(Vector2(9, 2))

func get_number_of_turns_till_reset():
	if number_of_turns_till_apocalypse <= 0:
		return 0
	else:
		return number_of_turns_till_apocalypse % 4

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
		if flat_game_board[idx] != null:
			var character = flat_game_board[idx]
			if character.is_evul() and !character.has_moved_current_turn:
				character.has_moved_current_turn = true
				idx += 1
				return character
		idx += 1
	
	current_enemy_idx = null
	return null

func xy_to_flat(x, y):
	return y * X + x

func flat_to_xy(idx):
	idx = int(idx)
	var x = idx % X
	var y = int(idx) / Y
	return Vector2(x, y)

func get_all_possible_movement_destinations_rec_func(idx, current_number_of_steps, max_movement, the_lava_is_floor):
	idx = int(idx)
	if number_of_steps_to[idx] == null:
		number_of_steps_to[idx] = current_number_of_steps
	else:
		number_of_steps_to[idx] = min(number_of_steps_to[idx], current_number_of_steps)

	if current_number_of_steps >= max_movement:
		return

	# Up
	var idx_up = idx + X
	if idx_up < SIZE and (flat_map[idx_up] or the_lava_is_floor) and (number_of_steps_to[idx_up]==null or number_of_steps_to[idx_up] > current_number_of_steps):
		get_all_possible_movement_destinations_rec_func(idx_up, current_number_of_steps+1, max_movement, the_lava_is_floor)

	# Down
	var idx_down = idx - X
	if idx_down >= 0 and (flat_map[idx_down] or the_lava_is_floor) and (number_of_steps_to[idx_down]==null or number_of_steps_to[idx_down] > current_number_of_steps):
		get_all_possible_movement_destinations_rec_func(idx_down, current_number_of_steps+1, max_movement, the_lava_is_floor)

	# Left
	var idx_left = idx - 1
	if idx_left/X == idx/X and idx_left>0 and (flat_map[idx_left] or the_lava_is_floor) and (number_of_steps_to[idx_left]==null or number_of_steps_to[idx_left] > current_number_of_steps):
		get_all_possible_movement_destinations_rec_func(idx_left, current_number_of_steps+1, max_movement, the_lava_is_floor)

	# Right
	var idx_right = idx + 1
	if idx_right/X == idx/X and idx_right<SIZE and (flat_map[idx_right] or the_lava_is_floor) and (number_of_steps_to[idx_right]==null or number_of_steps_to[idx_right] > current_number_of_steps):
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

func calc_dist(from, to, max_steps, the_lava_is_floor):
	for i in range(X*Y):
		number_of_steps_to[i] = null

	# Calculate all positions that can be reached. 
	var idx = xy_to_flat(from[0], from[1])
	get_all_possible_movement_destinations(idx, max_steps, the_lava_is_floor)
	var dist = number_of_steps_to[xy_to_flat(to[0], to[1])]
	return dist

func get_positions_of_good_chars_from_list_of_positions(positions):
	# Checks if there is a good character in any of the specified positions.
	# If it is, those positions are returned.
	# Otherwise an empty array is returned.
	var found_positions = []
	for pos in positions:
		var obj = get_obj_from_tile(pos[0], pos[1])
		if obj != null and obj.is_good():
			found_positions.append(pos)
	return found_positions

func get_movement(startX, startY, endX, endY):
	# Returns a Curve2D that goes from the start position
	# to the end position..

	var endIdx = xy_to_flat(endX, endY)
	if(flat_map[endIdx] == 0):
		push_error("MOVING TO TERRAIN THAT IS NOT ALLOWED!")

	var path = Curve2D.new()
	if startX != endX:
		for x in range(startX, endX + (1 if startX < endX else -1), 1 if startX < endX else -1):
			var world_pos = map_to_world_center(Vector2(x, startY))
			path.add_point(world_pos)

	if startY != endY:
		for y in range(startY, endY + (1 if startY < endY else -1), 1 if startY < endY else -1):
			var world_pos = map_to_world_center(Vector2(endX, y))
			path.add_point(world_pos)
	return path

func map_to_world_center(v : Vector2):
	return map_to_world(v) + Vector2.ONE * 16

func get_obj_from_tile(x, y):
	# Returns null if there is nothing there, otherwise it
	# returns the thing that is in the tile.
	if x < 0 or x >= X or y < 0 or y >= Y:
		return null
	else:
		return flat_game_board[xy_to_flat(x, y)]

func any_player_moves_left():
	for p in flat_game_board:
		if(p and p.is_good() and !p.has_moved_current_turn):
			return true
	return false

func reset_movement_of_good_chars():
	for p in flat_game_board:
		if(p and p.is_good()):
			p.has_moved_current_turn = false

func reset_movement_of_evul_chars():
	for p in flat_game_board:
		if(p and p.is_evul()):
			p.has_moved_current_turn = false

func _input(event):
	if event.is_action_pressed("ui_left_click"):
		var map_pos = world_to_map(event.position - position)
		var obj = get_obj_from_tile(map_pos[0], map_pos[1])
		
		match(game_state):
			game_states.player_turn:
				print(game_turn_state)
				match(game_turn_state):
					game_turn_states.choose_character:
						if (!obj or !obj.is_good() or obj.has_moved_current_turn):
							return
						active_character = obj
						obj.on_click(xy_to_flat(map_pos[0], map_pos[1]))
						game_turn_state = game_turn_states.select_tile
					
					game_turn_states.select_attack:
						var green = find_green(map_pos[0], map_pos[1])
						if (!green):
							# wait until we click a green or we cancel
							return
						
						# fallback, should not be needed?
						if (!obj or !obj.is_evul()):
							# cancel, next turn
							remove_green_tiles()
							reset_game_board()
							#game_turn_state = game_turn_states.choose_character
							return

						# attack!
						print("attack")
						var i = xy_to_flat(map_pos[0], map_pos[1])
						flat_game_board[i] = null

						obj.queue_free()
						remove_green_tiles()
						
						# TODO: next state
						game_turn_state = game_turn_states.choose_character
						
					game_turn_states.select_tile:
						var green = find_green(map_pos[0], map_pos[1])
						if (green):
							game_turn_state = game_turn_states.character_moving
							# TODO: get move path
							var path = get_movement(active_character.cx, active_character.cy, green.cx, green.cy)
							active_character.move_along_path(path)
							
							# Move character to new position
							# Check of there is an pickupable object on that position
							if flat_game_board[xy_to_flat(green.cx, green.cy)]:
								var objed_to_be_used = flat_game_board[xy_to_flat(green.cx, green.cy)]
								objed_to_be_used.on_pick_up(active_character)
								flat_game_board[xy_to_flat(green.cx, green.cy)].queue_free()
								flat_game_board[xy_to_flat(green.cx, green.cy)] = null

							flat_game_board[xy_to_flat(active_character.cx, active_character.cy)] = null
							flat_game_board[xy_to_flat(green.cx, green.cy)] = active_character
							active_character.set_coordinates_only(Vector2(green.cx, green.cy))
							
							remove_green_tiles()
						else:
							game_turn_state = game_turn_states.choose_character
							remove_green_tiles()

func end_of_enemy_turn():
	number_of_turns_till_apocalypse -= 1
	if number_of_turns_till_apocalypse <= 0:
		game_state = game_states.DEATH_DESTRUCTION_AND_THE_APOCALYPSE
		return

	print("TURNS LEFT ", get_number_of_turns_till_reset())
	if get_number_of_turns_till_reset() == 0:
		reset_game_board()

func end_of_player_turn():
	reset_movement_of_good_chars()
	
	# check winning condition
	if ($Rocket.is_character_nearby()):
		print("YOU WON")
		game_state = game_states.winning

func _on_reached_goal():
	print("callback hoolabandoola")

func _process(delta):
	match(game_state):
		game_states.player_turn:
			match(game_turn_state):
				game_turn_states.character_moving:
					if (active_character.has_reached_destination()):
						active_character.has_moved_current_turn = true

						# TODO: kolla om man kan attackera
						# if (can attack)
						if (place_attack_tiles(active_character.cx, active_character.cy)):
							# TODO: fixa nya place green tiles som visar var man kan attackera
							game_turn_state = game_turn_states.select_attack
						else:
							# TODO: select next turn
							game_turn_state = game_turn_states.choose_character
				game_turn_states.choose_character:
					if !any_player_moves_left():
						game_state = game_states.enemy_turn
						game_turn_state = game_turn_states.choose_character
						
						# end of player turn
						end_of_player_turn()
		game_states.enemy_turn:
			match(game_turn_state):
				game_turn_states.choose_character:
					var enemy = get_next_enemy()
					active_character = enemy
					if !enemy:
						# end of turn
						game_state = game_states.player_turn
						game_turn_state = game_turn_states.choose_character
						reset_movement_of_evul_chars()
						end_of_enemy_turn()
					else:
						game_turn_state = game_turn_states.character_moving
						
						# TODO: Move in to a function
						var max_look_distance = 5 # TODO: Should be enemy-dependant
						var destination = active_character.move_evul(xy_to_flat(active_character.cx, active_character.cy), max_look_distance)
						if (destination):
							var path = get_movement(active_character.cx, active_character.cy, destination[0], destination[1])
							active_character.move_along_path(path)

							# move enemy to new position
							flat_game_board[xy_to_flat(active_character.cx, active_character.cy)] = null
							flat_game_board[xy_to_flat(destination[0], destination[1])] = active_character
							active_character.set_coordinates_only(Vector2(destination[0], destination[1]))
						else:
							# Enemy takes no action
							game_turn_state = game_turn_states.choose_character
				game_turn_states.character_moving:
					if(active_character.has_reached_destination()):
						game_turn_state = game_turn_states.select_attack
				game_turn_states.select_attack:
					# Find someone to attack.
					var idx_of_victim = active_character.find_idx_of_victim()
					if idx_of_victim:
						flat_game_board[idx_of_victim].queue_free()
						flat_game_board[idx_of_victim] = null
					game_turn_state = game_turn_states.choose_character

				
				game_turn_states.end_turn:
					for character in resetting_characters:
						if (character.has_reached_destination()):
							resetting_characters.erase(character)
							active_character = null
							break
					
					if (resetting_characters.empty()):
						for character in get_tree().get_nodes_in_group("Characters"):
							character.reset_graphics()
						for enemy in get_tree().get_nodes_in_group("Enemies"):
							enemy.reset_graphics()
						
						game_turn_state = game_turn_states.choose_character

func find_green(x, y):
	for green in active_greens:
		if (green.cx == x and green.cy == y):
			return green
	return null

func place_green_tiles(x,y):
	var relevant_char = flat_game_board[xy_to_flat(x, y)]
	var can_relevant_person_walk_on_lava = relevant_char and relevant_char.can_walk_on_lava
	var greens = get_all_possible_movement_destinations(xy_to_flat(x,y), 3, can_relevant_person_walk_on_lava)

	# Remove the one corresponding to the current position
	for i in range(len(greens)):
		if greens[i][0] == x and greens[i][1] == y:
			greens.remove(i)
			break

	active_greens = []
	for vec in greens:
		if(flat_game_board[xy_to_flat(vec[0],vec[1])] == null or flat_game_board[xy_to_flat(vec[0],vec[1])].is_neutral()):
			var green = preload("res://Green.tscn")
			var GR = green.instance()
			self.add_child(GR)
			GR.set_coordinates(vec)
			active_greens.append(GR)

func remove_green_tiles():
	for tile in get_tree().get_nodes_in_group("green tiles"):
		tile.queue_free()
	active_greens = []
	
func place_attack_tiles(x,y):
	active_greens = []
	var attackable_tiles = [Vector2(x+1,y),Vector2(x-1,y),Vector2(x,y+1),Vector2(x,y-1)]
	var cancel_icon = preload("res://Cancel.tscn")
	var cancel = cancel_icon.instance()
	self.add_child(cancel)
	cancel.set_coordinates(Vector2(x+1,y+1))
	for vec in attackable_tiles:
		if(flat_game_board[xy_to_flat(vec[0],vec[1])] != null and flat_game_board[xy_to_flat(vec[0],vec[1])].is_evul()):
			var attack_icon = preload("res://Attack.tscn")
			var attackable = attack_icon.instance()
			self.add_child(attackable)
			attackable.set_coordinates(vec)
			active_greens.append(attackable)
	
	return !active_greens.empty()

func reset_game_board():
	game_turn_state = game_turn_states.end_turn
	resetting_characters = []
	
	for character in get_tree().get_nodes_in_group("Characters"):
		# reference character
		active_character = character
		character.move_to_start_coordinates()
		flat_game_board[xy_to_flat(character.cx, character.cy)] = null
		flat_game_board[xy_to_flat(character.startCoords.x, character.startCoords.y)] = character
		character.set_coordinates_only(character.startCoords)
		
		resetting_characters.append(character)
	
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		enemy.move_to_start_coordinates()
		flat_game_board[xy_to_flat(enemy.cx, enemy.cy)] = null
		flat_game_board[xy_to_flat(enemy.startCoords.x, enemy.startCoords.y)] = enemy
		enemy.set_coordinates_only(enemy.startCoords)
		
		resetting_characters.append(enemy)
