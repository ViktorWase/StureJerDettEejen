extends Node2D

var alignment

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
	position.x = tilemap.map_to_world(coord)[0] + 16
	position.y = tilemap.map_to_world(coord)[1] + 16
# end od MainDude

func _ready():
	set_blocking()
	
	$fire.hide()

func is_character_nearby():
	var tilemap = get_parent()
	var has_character = false
	for y in range(3):
		for x in range(3):
			var obj = tilemap.get_obj_from_tile(cx+x, cy+y)
			if (obj and obj.is_good()):
				return true
	return false
