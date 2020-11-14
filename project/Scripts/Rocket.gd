extends Spatial

var alignment
export var displayLeft = false
var thrustSpeed = 2
var thrustVelocity = 0
var is_going_to_space = false

# from MainDude
var cx : int
var cy : int

enum {
	good,
	neutral,
	evul,
	blocking,
	undefined
}

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

	var tilemap = get_parent()
	transform.origin.x = coord.x + tilemap.offsetX + 0.5
	transform.origin.z = coord.y + tilemap.offsetY + 0.5
# end od MainDude

func _ready():
	set_blocking()
	
	if (displayLeft):
		$HelpText/Arrow/LabelLeft.show()
		$HelpText/Arrow/LabelRight.hide()
	else:
		$HelpText/Arrow/LabelLeft.hide()
		$HelpText/Arrow/LabelRight.show()
	
	$ship/fire.hide()

func calculate_score():
	var remaining_time = get_parent().number_of_turns_till_apocalypse
	var number_of_units_close_to_rocket = 0
	for y in range(3):
		for x in range(3):
			var obj = get_parent().get_obj_from_tile(cx+x-1, cy+y-1)
			if (obj and obj.is_good()):
				number_of_units_close_to_rocket += 1

	return remaining_time + number_of_units_close_to_rocket  # TODO: Make this better somehow?

func is_character_nearby():
	var tilemap = get_parent()
	var has_character = false
	for y in range(3):
		for x in range(3):
			var obj = tilemap.get_obj_from_tile(cx+x-1, cy+y-1)
			if (obj and obj.is_good()):
				return true
	return false

func get_nearby_characters():
	var tilemap = get_parent()
	var characters = []
	for y in range(3):
		for x in range(3):
			var obj = tilemap.get_obj_from_tile(cx+x-1, cy+y-1)
			if (obj and obj.is_good()):
				characters.append(obj)
	return characters

func go_to_space():
	is_going_to_space = true
	$ship/fire.show()
	$RocketSound.play()

func show_help_text():
	$HelpText.show()

func hide_help_text():
	$HelpText.hide()

func _physics_process(delta):
	if (is_going_to_space):
		thrustVelocity += thrustSpeed*delta
		transform.origin += transform.basis.y*thrustVelocity*delta
