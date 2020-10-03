extends Sprite

signal reached_waypoint

enum {
	good,
	neutral,
	evul,
	undefined
}
var alignment = undefined
var max_walk_distance = 3
var waypoints
var waypoint_index
var velocity
export var move_speed = 20
var is_done_moving

var cx : int
var cy : int

# Called when the node enters the scene tree for the first time.
func _ready():
	return

func is_evul():
	return alignment == evul

func is_good():
	return alignment == good

func set_good():
	alignment = good

func set_evul():
	alignment = evul

func set_coordinates_only(coord):
	# kolla om vi får ett fel, hälsningar Intrud
	cx = coord.x
	cy = coord.y

func set_coordinates(coord):
	set_coordinates_only(coord)

	var tilemap = get_parent()
	position.x = tilemap.map_to_world(coord)[0] + 16
	position.y = tilemap.map_to_world(coord)[1] + 16

func move_evul(idx, max_look_distance):
	# Checks if there is a player within max_look_distance (not as the crow flies -
	# the terrain is taken in to account), if so the character moves in that
	# general direction. Otherwise it stands still.
	# Returns a vector with the coordinates of its destinations.
	
	# TODO: There is a lot of recalculation in this function. Might be worth fixing?
	# TODO: Possibly move it randomly or in a pattern if no char is detected?

	var possible_squares = get_parent().get_all_possible_movement_destinations(idx, max_look_distance)
	var positions_of_good_chars = get_parent().get_positions_of_good_chars_from_list_of_positions(possible_squares)
	
	if len(positions_of_good_chars) > 0:
		# Find closest good char.
		var from = get_parent().flat_to_xy(idx)
		var closest_dist = max_look_distance + 10
		var choosen_pos = null
		for pos in positions_of_good_chars:
			var dist = get_parent().calc_dist(from, pos, max_look_distance)
			if dist != null and dist < closest_dist:
				closest_dist = dist
				choosen_pos = pos
		if choosen_pos == null:
			push_error("You've done messed up proper, algo boy.")
		
		# Move towards the closest good char.
		var destinations = get_parent().get_all_possible_movement_destinations(idx, max_walk_distance)
		var best_dest = null
		var best_remaining_dist = null
		for dest in destinations:
			var remaining_dist = get_parent().calc_dist(dest, choosen_pos, max_look_distance)  # TODO: I think the max can be look-walk?
			if remaining_dist > 0: # We don't want to step on the opponent.
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

func on_click(idx):
	print("YOU CLICKED THE MAIN DUDE")
	var x = self.get_parent().flat_to_xy(idx)[0]
	var y = self.get_parent().flat_to_xy(idx)[1]
	self.get_parent().place_green_tiles(x,y)

func move_along_path(path : Curve2D):
	waypoints = path.get_baked_points()
	waypoint_index = 0
	is_done_moving = false

func has_reached_destination():
	# TODO: USE SIGNLARS
	if (is_done_moving):
		is_done_moving = false
		return true
	return false

func _physics_process(delta):
	if !waypoints:
		return
	# TODO: check if waypoints is empty
	var target = waypoints[waypoint_index]
	if position.distance_to(target) < 1:
		waypoint_index += 1
		if (waypoint_index >= len(waypoints)):
			waypoints = null
			print("end")
			is_done_moving = true
			# TODO
			# set_coordinates()
			return
		target = waypoints[waypoint_index]
	velocity = (target - position).normalized() * move_speed
	#velocity = move_and_slide(velocity)
	position += velocity*delta

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
