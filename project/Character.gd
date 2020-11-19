extends Spatial

signal reached_waypoint

enum Alignment {
	good,
	neutral,
	evul,
	undefined
}

var alignment = Alignment.undefined
var max_walk_distance = 2
var damage = 1
var waypoints
var waypoint_index
var velocity
var move_speed = 4
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
	has_moved_current_turn = false

	# tilt and offset the character sprite for a better effect
	$Sprite.transform.origin.z = 0.28
	$Sprite.rotation_degrees.x = -43

func get_attack_coordinates():
	return attack_coordinates

func is_attacked(damage):
	current_hp -= damage
	var is_dead = current_hp <= 0
	return is_dead

func is_evul():
	return alignment == Alignment.evul

func is_good():
	return alignment == Alignment.good
	
func is_neutral():
	return alignment == Alignment.neutral

func is_blocking():
	return alignment == Alignment.blocking

func set_good():
	alignment = Alignment.good

func set_evul():
	alignment = Alignment.evul
	
func set_neutral():
	alignment = Alignment.neutral

func can_stand_on(other_character):
	# The power-up class has a function with the same name that return true
	return false

func play_idle():
	push_error("Play idle in abstract base class, you doofus.")

func play_run():
	push_error("Play run in abstract base class, you doofus.")

func set_start_coordinates(coord : Vector2):
	startCoords = coord.floor()
	set_coordinates(startCoords)

func set_coordinates_only(coord):
	coord = coord.floor()
	cx = coord.x
	cy = coord.y

func set_coordinates(coord):
	set_coordinates_only(coord)

	var tilemap = get_parent()
	transform.origin.x = coord.x + tilemap.offsetX + 0.5
	transform.origin.z = coord.y + tilemap.offsetY + 0.5

func reset_graphics():
	play_idle()
	scale.x = abs(scale.x)

func find_idx_of_victim():
	# Checks if there is a neighbour that can be attacked!
	for neighbour_delta in attack_coordinates:
		var x = int(cx + neighbour_delta[0])
		var y = int(cy + neighbour_delta[1])
		
		if x >= 0 and y >= 0 and x < get_parent().X and y < get_parent().Y:
			var obj = get_parent().flat_game_board[get_parent().xy_to_flat(x, y)]
			if obj and ((is_evul() and obj.is_good()) or (obj.is_evul() and is_good())):
				return get_parent().xy_to_flat(x, y)
	return null

func on_click(idx):
	var x = self.get_parent().flat_to_xy(idx)[0]
	var y = self.get_parent().flat_to_xy(idx)[1]
	self.get_parent().place_green_tiles(x, y, max_walk_distance)

func move_along_path(path : Curve2D):
	waypoints = path.get_baked_points()
	print(waypoints)
	waypoint_index = 0
	is_done_moving = false

	play_run()

func move_to_start_coordinates():
	var tilemap = get_parent()
	waypoints = [startCoords + Vector2(tilemap.offsetX, tilemap.offsetY) + Vector2.ONE*0.5]
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
	var pos = get2dPos()
	if pos.distance_to(target) < 0.1:
		waypoint_index += 1
		if (waypoint_index >= len(waypoints)):
			play_idle()
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
	velocity = (target - pos).normalized() * move_speed
	
	if (velocity.x < -0.1):
		scale.x = -abs(scale.x)
	else:
		scale.x = abs(scale.x)
		
	#velocity = move_and_slide(velocity)
	transform.origin += Vector3(velocity.x, 0, velocity.y)*delta

func play_attack_sound():
	$AttackSound.play()

func play_foot_sound():
	$FootSound.play()

func darken_character():
	#modulate = Color(0.35,0.35,0.35,1.0)
	pass
	
func reset_darkened_character():
	#modulate = Color(1.0,1.0,1.0,1.0)
	pass

func get2dPos():
	return Vector2(transform.origin.x, transform.origin.z)
