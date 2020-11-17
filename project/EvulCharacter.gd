extends "res://Character.gd"

# This enum governs how the enemy behaves in battle.
# Currently it supports simple patterns, but I reckon
# I'll have to rewrite this as a proper class later to
# get more nuanced behaviour.
enum BattlePersonality {
	undefined,
	attackRandomlyOnlyIfItSeesAGoodGuy,
	runAwayUnlessPushedIntoCorner,
	planUsingAI
}
var personality = BattlePersonality.undefined

func has_battle_personality():
	# This is just for debugging. It should
	# always be true.
	return personality != BattlePersonality.undefined

func has_planning_personality():
	# If this is true, then the AI choose what they do.
	# Otherwise they do whatever they want.
	return personality == BattlePersonality.planUsingAI

func _init():
	set_evul()

func _ready():
	add_to_group("BadGuys")  # TODO: I think I renamed them? Same in GoodCharacter

func play_idle():
	assert(has_battle_personality())
	$AnimatedSprite.play("idle")

func can_see_any_good_guys(flat_board, sizex, sizey):
	assert(flat_board[cx + cy * sizex].is_evul())
	var watch_distance_square = max_watch_distance * max_watch_distance

	var counter = 0
	for x in range(sizex):
		for y in range(sizey):
			if flat_board[counter] and flat_board[counter].is_good():
				var dist_square = (x-cx)*(x-cx) + (y-cy)*(y-cy)
				if dist_square <= watch_distance_square:
					return true
			counter += 1
	return false

func pick_random_good_guy_neighbour(positions_of_good_chars):
	assert(len(positions_of_good_chars) > 0)
	var r = randi()%len(positions_of_good_chars)
	return positions_of_good_chars[r]
	"""
	var indexes_of_neighbours = []
	for i in range(len(positions_of_good_chars)):
		var manhattan_dist = abs(positions_of_good_chars[i][0]-cx) + abs(positions_of_good_chars[i][1]-cy)
		assert(manhattan_dist > 0)
		if manhattan_dist == 1:
			indexes_of_neighbours.append(i)
	assert(len(indexes_of_neighbours) > 0)
	assert(len(indexes_of_neighbours) <= 4)
	var r = randi()%len(indexes_of_neighbours)
	return positions_of_good_chars[indexes_of_neighbours[r]]
	"""

func move_evul(idx, flat_board, sizex, sizey):
	assert(has_battle_personality())
	assert(self.has_battle_personality())
	if self.can_see_any_good_guys(flat_board, sizex, sizey):
		match self.personality:
			BattlePersonality.runAwayUnlessPushedIntoCorner:
				assert(false, "Not implemented")
			BattlePersonality.attackRandomlyOnlyIfItSeesAGoodGuy:
				
				return move_opportunist(idx)
			_:
				assert(false, "NOT A PERSONALITY TYPE!")
	else:
		# Otherwise, stay still.
		return {"old_pos": [cx, cy], "new_pos": [cx, cy], "attacked_pos": null}

func move_opportunist(idx):
	# This is for enemies with the personality 'attackRandomlyOnlyIfItSeesAGoodGuy'
	# Checks if there is a player within max_watch_distance (not as the crow flies -
	# the terrain is taken in to account), if so the character moves in that
	# general direction. Otherwise it stands still.
	# Returns a vector with the coordinates of its destinations.
	
	# TODO: There is a lot of recalculation in this function. Might be worth fixing?
	# TODO: THIS WILL NOT WORK FOR SNIPERS! They should stay at a distance, but this
	#       code will put them as close as possible.

	var possible_squares = get_parent().get_all_possible_movement_destinations(idx, max_watch_distance, can_walk_on_lava)
	var positions_of_good_chars = get_parent().get_positions_of_good_chars_from_list_of_positions(possible_squares)
	
	var move = {"old_pos": [cx, cy]}

	if len(positions_of_good_chars) > 0:
		# Find closest good char.
		var from = get_parent().flat_to_xy(idx)
		var closest_dist = max_watch_distance + 10
		var choosen_pos = null
		for pos in positions_of_good_chars:
			var dist = get_parent().calc_dist(from, pos, max_watch_distance, can_walk_on_lava)
			if dist != null and dist < closest_dist:
				closest_dist = dist
				choosen_pos = pos
		if choosen_pos == null:
			assert(false, "You've done messed up proper, algo boy.")
		
		# Move towards the closest good char.
		var destinations = get_parent().get_all_possible_movement_destinations(idx, max_walk_distance, can_walk_on_lava)
		var best_dest = null
		var best_remaining_dist = null
		for dest in destinations:
			var remaining_dist = get_parent().calc_dist(dest, choosen_pos, max_watch_distance, can_walk_on_lava)  # TODO: I think the max can be look-walk?

			if remaining_dist and remaining_dist > 0: # We don't want to step on the opponent.
				if remaining_dist == 1: # This is the best case scenario.
					best_dest = dest
					# Pick a random person to attack
					var attack_pos = pick_random_good_guy_neighbour(positions_of_good_chars)
					# TODO: Add attack position here.
					move["attacked_pos"] = attack_pos
					break
				else:
					if best_remaining_dist == null or remaining_dist < best_remaining_dist:
						best_remaining_dist = remaining_dist
						best_dest = dest
		if best_dest == null or best_remaining_dist == null:
			assert(false, "You are the bringer of great shame.")
		move["new_pos"] = best_dest
		if not move.has("attacked_pos"):
			move["attacked_pos"] = null
	else:
		move["new_pos"] = [cx, cy]
		move["attacked_pos"] = null
	assert(move.has("attacked_pos"))
	return move
