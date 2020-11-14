extends Node

var flat_game_board
var flat_map
var number_of_steps_to
var active_greens = []

# variables for the map
var width
var height
var offsetX
var offsetY
var tileSize = 1

var X = 10
var Y = 10
var SIZE = X * Y
var current_enemy_idx = null
var active_character
var resetting_characters = []
var number_of_turns_till_apocalypse = 12
var planned_enemy_movements = []
var planned_enemy_movements_counter = 0

var end_counter # used to insert a time padding when resetting the board

var GUI
var Camera
var tileMap

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

var game_state
var game_turn_state

# Called when the node enters the scene tree for the first time.
func _ready():
	# get reference to GUI and camera
	GUI = get_tree().get_root().get_node("Node2D").get_node("GUI")
	Camera = get_tree().get_root().get_node("Node2D").get_node("Camera")
	tileMap = get_tree().get_root().get_node("Node2D").get_node("TileMap")
	
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
	var cells = tileMap.get_used_cells()
	var minX = 0
	var maxX = 0
	var minY = 0
	var maxY = 0
	for cell in cells:
		minX = min(minX, cell.x)
		maxX = max(maxX, cell.x)
		minY = min(minY, cell.z)
		maxY = max(maxY, cell.z)
	X = int(maxX - minX) + 1
	Y = int(maxY - minY) + 1
	SIZE = X * Y
	
	offsetX = minX
	offsetY = minY
	width = X
	height = Y

	#var idx = 0
	for _y in range(Y):  # TODO: Y is too small, and also it's set somewhere else I think.
		for _x in range(X):
			flat_game_board.append(null)
			number_of_steps_to.append(false)
			flat_map.append(0)
	
	# populate flat map
	for cell in cells:
		var i = xy_to_flat(cell.x - offsetX, cell.z - offsetY)
		flat_map[i] = 1

	# This is were the level is created.
	if tileMap.has_method("update_bitmask_region"):
		tileMap.update_bitmask_region(Vector2(0, 0), Vector2(X, Y))
	
	for character in get_tree().get_nodes_in_group("GoodGuys"):
		var p = character.get2dPos()
		var charX = floor(p.x) - offsetX
		var charY = floor(p.y) - offsetY
		var i = xy_to_flat(charX, charY)
		#character.set_as_basic_b()
		flat_game_board[i] = character
		
		character.play_idle()
		character.set_start_coordinates(Vector2(charX, charY))
	
	for enemy in get_tree().get_nodes_in_group("BadGuys"):
		var p = enemy.get2dPos()
		var charX = floor(p.x) - offsetX
		var charY = floor(p.y) - offsetY
		var i = xy_to_flat(charX, charY)
		flat_game_board[i] = enemy
		enemy.play_idle()
		enemy.set_start_coordinates(Vector2(charX, charY))
	
	var rocket = $Rocket
	var charX = floor(rocket.transform.origin.x) - offsetX
	var charY = floor(rocket.transform.origin.z) - offsetY
	var i = xy_to_flat(charX, charY)
	flat_game_board[i] = rocket
	rocket.set_coordinates(Vector2(charX, charY))
	
	GUI.get_node("TurnInfo").text = ""
	GUI.get_node("End Turn").hide()
	GUI.get_node("WinningScreen").hide()
	GUI.get_node("DeathScreen").hide()
	
	GUI.connect("end_turn_pressed", tileMap, "_on_end_turn_pressed")
	GUI.connect("restart_pressed", tileMap, "_on_restart_pressed")
	
	reset_loop_icons()

	# player starts
	set_player_turn()
	
	$Rocket.show_help_text()
	$GameStartJingle.play()
	
	$AI.setup(flat_map, X, Y)

	emit_signal("ready", tileMap)

func _on_end_turn_pressed():
	$Rocket.hide_help_text()
	GUI.play_menu_sound()
	
	player_ends_their_turn()

func _on_restart_pressed():
	get_tree().reload_current_scene()

func set_player_turn():
	game_state = game_states.player_turn
	game_turn_state = game_turn_states.choose_character
	
	GUI.get_node("TurnInfo").text = "Player turn"
	
#	if should_be_able_to_end_player_turn():
	GUI.get_node("End Turn").show()

	update_loop_icons()

func set_enemy_turn():
	game_state = game_states.enemy_turn
	game_turn_state = game_turn_states.choose_character
	
	GUI.get_node("TurnInfo").text = "Enemy turn"
	
	GUI.get_node("End Turn").hide()
	
	update_loop_icons()

func get_number_of_turns_till_reset():
	if number_of_turns_till_apocalypse <= 0:
		return 0
	else:
		return number_of_turns_till_apocalypse % 4

func reset_loop_icons():
	GUI.get_node("Loop Counter/LoopIcon1").frame = 0
	GUI.get_node("Loop Counter/LoopIcon1").material.set_shader_param("tint", Vector3(0,0,0))
	GUI.get_node("Loop Counter/LoopIcon2").frame = 0
	GUI.get_node("Loop Counter/LoopIcon2").material.set_shader_param("tint", Vector3(0,0,0))
	GUI.get_node("Loop Counter/LoopIcon3").frame = 0
	GUI.get_node("Loop Counter/LoopIcon3").material.set_shader_param("tint", Vector3(0,0,0))

func update_loop_icons():
	if number_of_turns_till_apocalypse > 8:
		GUI.get_node("Loop Counter/LoopIcon3").frame = get_number_of_turns_till_reset()
		GUI.get_node("Loop Counter/LoopIcon3").material.set_shader_param("tint", Vector3(1,1,0))
	elif number_of_turns_till_apocalypse > 4:
		GUI.get_node("Loop Counter/LoopIcon3").frame = 4
		GUI.get_node("Loop Counter/LoopIcon2").frame = get_number_of_turns_till_reset()
		GUI.get_node("Loop Counter/LoopIcon2").material.set_shader_param("tint", Vector3(1,1,0))
	elif number_of_turns_till_apocalypse > 0:
		GUI.get_node("Loop Counter/LoopIcon2").frame = 4
		GUI.get_node("Loop Counter/LoopIcon1").frame = get_number_of_turns_till_reset()
		GUI.get_node("Loop Counter/LoopIcon1").material.set_shader_param("tint", Vector3(1,1,0))
	else:
		GUI.get_node("Loop Counter/LoopIcon1").frame = 4

func get_next_enemy(): # TODO: Remove. It should not be needed anymore.
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
	if x < 0 or x >= X or y < 0 or y >= Y:
		return -1
	var idx = y * X + x
	return idx

func flat_to_xy(idx):
	idx = int(idx)
	var y = floor(idx / X)
	var x = idx - y * X
	return Vector2(x, y)

func are_all_good_guys_dead():
	for p in flat_game_board:
		if p and p.is_good():
			return false
	return true

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

func get_all_possible_movement_destinations(pos, max_movement, the_lava_is_floor=false):  # TODO: Remove.
#	for i in range(X*Y):
#		number_of_steps_to[i] = null
#
#	# Calculate all positions that can be reached. 
#	get_all_possible_movement_destinations_rec_func(idx, 0, max_movement, the_lava_is_floor)
#
#	# Convert to a more readable data format. 
#	var destinations = []
#	for idx in range(SIZE):
#		if number_of_steps_to[idx] != null:
#			var pos = flat_to_xy(idx)
#			destinations.append(pos)

	# generate possible destinations
	var positions = []
	# a simple line function
	for x1 in range(max_movement):
		for y1 in range(1, max_movement - x1 + 1):
			# rotate the triangle to fill every quadrant
			positions.append(Vector2(x1, y1))
			positions.append(Vector2(-y1, x1))
			positions.append(Vector2(-x1, -y1))
			positions.append(Vector2(y1, -x1))

	# add valid positions
	var destinations = []
	for p in positions:
		p += pos
		if is_valid_position(p, the_lava_is_floor):
			destinations.append(p)

	return destinations

func is_valid_position(p, the_lava_is_floor=false):
	var i = xy_to_flat(p.x, p.y)
	var valid = i >= 0 and i < SIZE and (flat_map[i] or the_lava_is_floor)
	return valid

func calc_dist(from, to, max_steps, the_lava_is_floor):
	for i in range(X*Y):
		number_of_steps_to[i] = null

	# Calculate all positions that can be reached.
	get_all_possible_movement_destinations(from, max_steps, the_lava_is_floor)
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
	path.bake_interval = 0.5
	if startX != endX:
		for x in range(startX, endX + (1 if startX < endX else -1), 1 if startX < endX else -1):
			var world_pos = map_to_world_center(Vector2(x, startY))
			path.add_point(world_pos)

	if startY != endY:
		for y in range(startY, endY + (1 if startY < endY else -1), 1 if startY < endY else -1):
			var world_pos = map_to_world_center(Vector2(endX, y))
			path.add_point(world_pos)
	
	if startX == endX and startY == endY:
		var world_pos = map_to_world_center(Vector2(endX, endY))
		path.add_point(world_pos)
		
	return path

func map_to_world_center(v : Vector2):
	return v + Vector2(offsetX, offsetY) + Vector2.ONE * 0.5

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
		var map_pos = Camera.world_to_map(event)
		var obj = get_obj_from_tile(map_pos[0], map_pos[1])
		
		match(game_state):
			game_states.player_turn:
				
				match(game_turn_state):
					game_turn_states.choose_character:
						if (!obj or !obj.is_good() or obj.has_moved_current_turn):
							return
						active_character = obj
						obj.on_click(xy_to_flat(map_pos[0], map_pos[1]))
						game_turn_state = game_turn_states.select_tile
						
						GUI.play_menu_sound()
						
						$Rocket.hide_help_text()
					
					game_turn_states.select_attack:
						if active_character == null:
							push_error("The active char is null in select attack")
						var green = find_green(map_pos[0], map_pos[1])
						if (!green):
							# wait until we click a green or we cancel
							return
							
						if (green in get_tree().get_nodes_in_group("cancel")):
							remove_green_tiles()
							active_character.darken_character()
							game_turn_state = game_turn_states.choose_character
							return
							
						# attack!
						print("attack")
						var idx_of_victim = xy_to_flat(map_pos[0], map_pos[1])
						if !flat_game_board[idx_of_victim]:
							push_error("You are attacking nothing!")
						var is_dead = flat_game_board[idx_of_victim].is_attacked(active_character.damage)
						if is_dead:
							if obj == active_character:
								push_error("The character managed to kill himself. This is frowned apon.")
							flat_game_board[idx_of_victim] = null
							obj.queue_free()
							
						remove_green_tiles()
						active_character.darken_character()
						active_character.play_attack_sound()
						
						# set next player turn
						set_player_turn()
						
					game_turn_states.select_tile:
						var green = find_green(map_pos[0], map_pos[1])
						if (green):
							if active_character == null:
								push_error("There are green tiles, but the character is null. Would you like to explain how that happened?")
							game_turn_state = game_turn_states.character_moving
							# TODO: get move path
							var path = get_movement(active_character.cx, active_character.cy, green.cx, green.cy)
							active_character.move_along_path(path)
							
							# Move character to new position
							# Check of there is an pickupable object on that position
							if flat_game_board[xy_to_flat(green.cx, green.cy)]:
								var objed_to_be_used = flat_game_board[xy_to_flat(green.cx, green.cy)]
								active_character.set_target_pickup(objed_to_be_used)

							flat_game_board[xy_to_flat(active_character.cx, active_character.cy)] = null
							flat_game_board[xy_to_flat(green.cx, green.cy)] = active_character
							active_character.set_coordinates_only(Vector2(green.cx, green.cy))
							
							active_character.play_foot_sound()
							
							remove_green_tiles()
						else:
							remove_green_tiles()
							# set next player turn
							set_player_turn()

func end_of_enemy_turn():
	reset_movement_of_evul_chars()

	number_of_turns_till_apocalypse -= 1
	if number_of_turns_till_apocalypse <= 0 or are_all_good_guys_dead():
		GUI.get_node("End Turn").hide()
		GUI.get_node("TurnInfo").text = ""
		GUI.get_node("DeathScreen").show()
		$DeathSound.play()
		game_state = game_states.DEATH_DESTRUCTION_AND_THE_APOCALYPSE
		return
	
	for character in get_tree().get_nodes_in_group("GoodGuys"):
		character.reset_darkened_character()

	print("TURNS LEFT ", get_number_of_turns_till_reset())
	if get_number_of_turns_till_reset() == 0:
		reset_game_board()
	else:
		# players turn!
		set_player_turn()

func should_be_able_to_end_player_turn():
	# Sometimes the player can end their turn. Other times, they cannot.
	# For exmaple, when it's the enemy's turn, or when a character is moving.
	return game_state == game_states.player_turn and game_turn_state == game_turn_states.choose_character

func player_ends_their_turn():
	if should_be_able_to_end_player_turn():
		end_of_player_turn()
	else:
		push_warning("Stop trying to end player turn when it's not allowed!")

func end_of_player_turn():
	reset_movement_of_good_chars()
	
	if (active_character):
		active_character.darken_character()

	# check winning condition
	if ($Rocket.is_character_nearby()):
		print("winning")
		GUI.get_node("End Turn").hide()
		GUI.get_node("TurnInfo").text = ""
		GUI.get_node("WinningScreen").show()
		for character in $Rocket.get_nearby_characters():
			flat_game_board[xy_to_flat(character.cx, character.cy)] = null
			character.queue_free()
		$Rocket.go_to_space()
		game_state = game_states.winning
		
		# wait a few seconds before changing level
		yield(get_tree().create_timer(4.0), "timeout")
		
		Global.load_next_level()
	else:
		planned_enemy_movements = $AI.get_moves(flat_game_board)
		planned_enemy_movements_counter = 0
		# enemies turn!
		set_enemy_turn()

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
						if (place_attack_tiles(active_character.cx, active_character.cy, active_character.get_attack_coordinates())):
							GUI.get_node("End Turn").hide()
							game_turn_state = game_turn_states.select_attack
						else:
							active_character.darken_character()
							# set next player turn
							set_player_turn()
				game_turn_states.choose_character:
					if !any_player_moves_left():
						# end of player turn
						end_of_player_turn()
		game_states.enemy_turn:
			GUI.get_node("End Turn").hide()
			match(game_turn_state):
				game_turn_states.choose_character:
					var enemy = null
					if planned_enemy_movements_counter != len(planned_enemy_movements):
						var current_enemy_pos = planned_enemy_movements[planned_enemy_movements_counter]["old_pos"]
						var current_idx = current_enemy_pos[0] + current_enemy_pos[1] * X
						assert(flat_game_board[current_idx] != null)
						enemy = flat_game_board[current_idx]
					active_character = enemy
					if !enemy:
						# end of turn
						end_of_enemy_turn()
					else:
						game_turn_state = game_turn_states.character_moving
						
						# TODO: Move in to a function
						#var max_look_distance = 5 # TODO: Should be enemy-dependant
						var destination = planned_enemy_movements[planned_enemy_movements_counter]["new_pos"]#active_character.move_evul(xy_to_flat(active_character.cx, active_character.cy), max_look_distance)
						assert(len(destination) == 2)
						var path = get_movement(active_character.cx, active_character.cy, destination[0], destination[1])
						active_character.move_along_path(path)
						# move enemy to new position
						flat_game_board[xy_to_flat(active_character.cx, active_character.cy)] = null
						flat_game_board[xy_to_flat(destination[0], destination[1])] = active_character
						active_character.set_coordinates_only(Vector2(destination[0], destination[1]))
						
						active_character.play_foot_sound()
				game_turn_states.character_moving:
					if(active_character.has_reached_destination()):
						game_turn_state = game_turn_states.select_attack
				game_turn_states.select_attack:
					# Find someone to attack.
					#var idx_of_victim = active_character.find_idx_of_victim()
					var attacked_pos = planned_enemy_movements[planned_enemy_movements_counter]["attacked_pos"]
					if attacked_pos:
						var idx_of_victim = xy_to_flat(attacked_pos[0], attacked_pos[1])
						print("FOUDN VICTIM")
						var victim = flat_game_board[idx_of_victim]
						var is_dead = victim.is_attacked(active_character.damage)
						if is_dead:
							flat_game_board[idx_of_victim].queue_free()
							flat_game_board[idx_of_victim] = null
						
						active_character.play_attack_sound()
					
					game_turn_state = game_turn_states.choose_character
					planned_enemy_movements_counter += 1

				game_turn_states.end_turn:
					end_counter -= delta
					
					for character in resetting_characters:
						if (character.has_reached_destination()):
							resetting_characters.erase(character)
							break

					if (resetting_characters.empty() and end_counter <= 0):
						for character in get_tree().get_nodes_in_group("GoodGuys"):
							character.reset_graphics()
						for enemy in get_tree().get_nodes_in_group("BadGuys"):
							enemy.reset_graphics()
						
						GUI.hide_ripples_effect()

						# player turn!
						set_player_turn()

func find_green(x, y):
	for green in active_greens:
		if (green.cx == x and green.cy == y):
			return green
	return null

func place_green_tiles(x,y, max_movement):
	var relevant_char = flat_game_board[xy_to_flat(x, y)]
	var can_relevant_person_walk_on_lava = relevant_char and relevant_char.can_walk_on_lava
	var greens = get_all_possible_movement_destinations(Vector2(x, y), max_movement, can_relevant_person_walk_on_lava)

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
			tileMap.add_child(GR)
			GR.set_coordinates(vec)
			active_greens.append(GR)

func remove_green_tiles():
	for tile in get_tree().get_nodes_in_group("green tiles"):
		tile.queue_free()
	active_greens = []
	
func place_attack_tiles(x,y, attackable_tiles):
	active_greens = []
	for vec in attackable_tiles:
		var pos = Vector2(vec[0] + x, vec[1] + y)
		var idx = xy_to_flat(pos.x, pos.y)
		if is_valid_position(pos) and flat_game_board[idx] and flat_game_board[idx].is_evul():
			var attack_icon = preload("res://Attack.tscn")
			var attackable = attack_icon.instance()
			tileMap.add_child(attackable)
			attackable.set_coordinates(vec + Vector2(x, y))
			active_greens.append(attackable)
	if(active_greens != []):
		var cancel_icon = preload("res://Cancel.tscn")
		var cancel = cancel_icon.instance()
		tileMap.add_child(cancel)
		cancel.set_coordinates(Vector2(x+1,y+1))
		active_greens.append(cancel)
	
	return !active_greens.empty()

func reset_game_board():
	game_turn_state = game_turn_states.end_turn
	game_state = game_states.enemy_turn
	resetting_characters = []
	end_counter = 1.4 # least number of seconds to wait before continuing
	
	for character in get_tree().get_nodes_in_group("GoodGuys"):
		character.move_to_start_coordinates()
		flat_game_board[xy_to_flat(character.cx, character.cy)] = null
		flat_game_board[xy_to_flat(character.startCoords.x, character.startCoords.y)] = character
		character.set_coordinates_only(character.startCoords)
		
		resetting_characters.append(character)
	
	for enemy in get_tree().get_nodes_in_group("BadGuys"):
		enemy.move_to_start_coordinates()
		flat_game_board[xy_to_flat(enemy.cx, enemy.cy)] = null
		flat_game_board[xy_to_flat(enemy.startCoords.x, enemy.startCoords.y)] = enemy
		enemy.set_coordinates_only(enemy.startCoords)
		
		resetting_characters.append(enemy)
	
	GUI.get_node("TurnInfo").text = ""
	GUI.show_ripples_effect()
	$WarpSound.play()
