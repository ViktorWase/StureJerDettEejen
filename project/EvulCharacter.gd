extends "res://Character.gd"

func _init():
	set_evul()

func _ready():
	add_to_group("Enemies")  # TODO: I think I renamed them? Same in GoodCharacter

func play_idle():
	$Sprite/AnimatedSprite.play("idle")

func move_evul(idx, max_look_distance):
	# Checks if there is a player within max_look_distance (not as the crow flies -
	# the terrain is taken in to account), if so the character moves in that
	# general direction. Otherwise it stands still.
	# Returns a vector with the coordinates of its destinations.
	
	# TODO: There is a lot of recalculation in this function. Might be worth fixing?
	# TODO: Possibly move it randomly or in a pattern if no char is detected?
	# TODO: THIS WILL NOT WORK FOR SNIPERS! They should stay at a distance, but this
	#       code will put them as close as possible.

	var possible_squares = get_parent().get_all_possible_movement_destinations(idx, max_look_distance, can_walk_on_lava)
	var positions_of_good_chars = get_parent().get_positions_of_good_chars_from_list_of_positions(possible_squares)
	
	if len(positions_of_good_chars) > 0:
		# Find closest good char.
		var from = get_parent().flat_to_xy(idx)
		var closest_dist = max_look_distance + 10
		var choosen_pos = null
		for pos in positions_of_good_chars:
			var dist = get_parent().calc_dist(from, pos, max_look_distance, can_walk_on_lava)
			if dist != null and dist < closest_dist:
				closest_dist = dist
				choosen_pos = pos
		if choosen_pos == null:
			push_error("You've done messed up proper, algo boy.")
		
		# Move towards the closest good char.
		var destinations = get_parent().get_all_possible_movement_destinations(idx, max_walk_distance, can_walk_on_lava)
		var best_dest = null
		var best_remaining_dist = null
		for dest in destinations:
			var remaining_dist = get_parent().calc_dist(dest, choosen_pos, max_look_distance, can_walk_on_lava)  # TODO: I think the max can be look-walk?

			if remaining_dist and remaining_dist > 0: # We don't want to step on the opponent.
				if remaining_dist == 1: # This is the best case scenario.
					return dest
				else:
					if best_remaining_dist == null or remaining_dist < best_remaining_dist:
						best_remaining_dist = remaining_dist
						best_dest = dest
		if best_dest == null or best_remaining_dist == null:
			push_error("You are the bringer of great shame.")
		return best_dest
	else:
		return 
