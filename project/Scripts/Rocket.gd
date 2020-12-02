extends Node2D

# TODO: Do we really need this this class?

var alignment
export var thrustSpeed = 40
export var displayLeft = false
var thrustVelocity = 0
var is_going_to_space = false

# from MainDude
var cx : int
var cy : int

var tilemap

enum {
	good,
	neutral,
	evul,
	blocking,
	undefined
}

func is_item():
	return false

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

func set_coordinates_only(coord):
	coord = coord.floor()
	# kolla om vi får ett fel, hälsningar Intrud
	cx = coord.x
	cy = coord.y

func set_coordinates(coord):
	set_coordinates_only(coord)

	position.x = tilemap.map_to_world(coord)[0] + 16
	position.y = tilemap.map_to_world(coord)[1] + 16
# end od MainDude

func _ready():
	set_blocking()
	
	if (displayLeft):
		$HelpText/Arrow/LabelLeft.show()
		$HelpText/Arrow/LabelRight.hide()
	else:
		$HelpText/Arrow/LabelLeft.hide()
		$HelpText/Arrow/LabelRight.show()
	
	$fire.hide()

	tilemap = get_parent().get_parent()

func calculate_score():
	var remaining_time = tilemap.number_of_turns_till_apocalypse
	var number_of_units_close_to_rocket = 0
	for y in range(3):
		for x in range(3):
			var obj = tilemap.get_obj_from_tile(cx+x-1, cy+y-1)
			if (obj and obj.is_good()):
				number_of_units_close_to_rocket += 1

	return remaining_time + number_of_units_close_to_rocket  # TODO: Make this better somehow?

func is_character_nearby():
	for y in range(3):
		for x in range(3):
			var obj = tilemap.get_obj_from_tile(cx+x-1, cy+y-1)
			if (obj and obj.is_good()):
				return true
	return false

func get_nearby_characters():
	var characters = []
	for y in range(3):
		for x in range(3):
			var obj = tilemap.get_obj_from_tile(cx+x-1, cy+y-1)
			if (obj and obj.is_good()):
				characters.append(obj)
	return characters

func go_to_space():
	is_going_to_space = true
	$fire.show()
	$RocketSound.play()

func show_help_text():
	$HelpText.show()

func hide_help_text():
	$HelpText.hide()

func _physics_process(delta):
	if (is_going_to_space):
		thrustVelocity += thrustSpeed*delta
		position += Vector2.UP*thrustVelocity*delta
