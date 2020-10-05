extends AnimatedSprite

signal reached_waypoint

enum {
	good,
	neutral,
	evul,
	blocking,
	undefined
}

enum Alignment {
	good,
	neutral,
	evul,
	blocking
}

enum PickupType {
	NA,
	wings,
	shield
}

export(PickupType) var pickup_type = PickupType.NA
export(Alignment) var type = Alignment.good
var alignment = undefined

var max_walk_distance = 2
var damage = 1
var waypoints
var waypoint_index
var velocity
export var move_speed = 20
var is_done_moving
var has_moved_current_turn
var can_walk_on_lava = false
var attack_coordinates = []
var target_pickup

var max_hp = 1
var current_hp = 1

var cx : int
var cy : int

var startCoords : Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	match(type):
		Alignment.good:
			set_good()
		Alignment.evul:
			set_evul()
		Alignment.neutral:
			set_neutral()
		Alignment.blocking:
			set_blocking()

	play("idle")
	has_moved_current_turn = false

func get_attack_coordinates():
	return attack_coordinates

# TODO: Change sprite in these functions
func set_as_runner():
	set_as_basic_b()
	max_walk_distance = 3

func set_as_sniper():
	set_as_basic_b()
	max_walk_distance = 1
	
	attack_coordinates = []
	for x in range(-3, 3+1):
		for y in range(-3, 3+1):
			var diff = abs(x) + abs(y)
			if diff > 1 and diff <= 3:
				attack_coordinates.append(Vector2(x, y))

func set_as_basic_b():
	max_walk_distance = 2
	max_hp = 1
	current_hp = 1
	damage = 1
	attack_coordinates = [Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0), Vector2(0, -1)]
	
func set_as_heavy_unit():
	set_as_basic_b()
	damage = 2
	max_hp = 2
	current_hp = max_hp

func is_attacked(damage):
	current_hp -= damage
	var is_dead = current_hp <= 0
	return is_dead

func is_evul():
	return alignment == evul

func is_good():
	return alignment == good
	
func is_neutral():
	return alignment == neutral

func is_blocking():
	return alignment == blocking

func set_good():
	alignment = good

func set_evul():
	alignment = evul
	
func set_neutral():
	alignment = neutral

func set_blocking():
	alignment = blocking

func set_start_coordinates(coord : Vector2):
	startCoords = coord.floor()
	set_coordinates(startCoords)

func set_coordinates_only(coord):
	coord = coord.floor()
	# kolla om vi får ett fel, hälsningar Intrud
	cx = coord.x
	cy = coord.y

func on_pick_up(pickerupper):
	if !is_neutral():
		push_error("You are trying to pick up a person - it's not type of game, you know.")

	match(pickup_type):
		PickupType.wings:
			print("Picking up wings")
			pickerupper[0].can_walk_on_lava = true
			pickerupper[0].get_node("Wings_equipped").show()
		PickupType.shield:
			print("Picking up armor")
			pickerupper[0].max_hp += 1
			pickerupper[0].current_hp += 1
			pickerupper[0].get_node("Shield_equipped").show()
		_:
			push_error("No object called " + pickup_type)

func set_coordinates(coord):
	set_coordinates_only(coord)

	var tilemap = get_parent()
	position.x = tilemap.map_to_world(coord)[0] + 16
	position.y = tilemap.map_to_world(coord)[1] + 16

func reset_graphics():
	play("idle")
	scale.x = abs(scale.x)

func find_idx_of_victim():
	# Checks if there is a neighbour that can be attacked!
	for neighbour_delta in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
		var x = int(cx + neighbour_delta[0])
		var y = int(cy + neighbour_delta[1])
		
		if x >= 0 and y >= 0 and x < get_parent().X and y < get_parent().Y:
			var obj = get_parent().flat_game_board[get_parent().xy_to_flat(x, y)]
			if obj and ((is_evul() and obj.is_good()) or (obj.is_evul() and is_good())):
				return get_parent().xy_to_flat(x, y)
	return null

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

func on_click(idx):
	print("YOU CLICKED THE MAIN DUDE")
	var x = self.get_parent().flat_to_xy(idx)[0]
	var y = self.get_parent().flat_to_xy(idx)[1]
	self.get_parent().place_green_tiles(x, y, max_walk_distance)

func move_along_path(path : Curve2D):
	waypoints = path.get_baked_points()
	waypoint_index = 0
	is_done_moving = false
	
	play("run")

func move_to_start_coordinates():
	waypoints = [get_parent().map_to_world(startCoords) + Vector2.ONE*16]
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
			play("idle")
			waypoints = null
			print("end")
			is_done_moving = true
			# TODO
			# set_coordinates()
			
			if (target_pickup):
				target_pickup.on_pick_up([self])
				print("CHAR HP: ", current_hp)
				target_pickup.queue_free()
				target_pickup = null
			
			return
		target = waypoints[waypoint_index]
	velocity = (target - position).normalized() * move_speed
	
	if (velocity.x < -32):
		scale.x = -abs(scale.x)
	else:
		scale.x = abs(scale.x)
		
	#velocity = move_and_slide(velocity)
	position += velocity*delta

func set_target_pickup(pickup):
	target_pickup = pickup

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func play_attack_sound():
	$AttackSound.play()

func play_foot_sound():
	$FootSound.play()

func darken_character():
	modulate = Color(0.35,0.35,0.35,1.0)
	
func reset_darkened_character():
	modulate = Color(1.0,1.0,1.0,1.0)
