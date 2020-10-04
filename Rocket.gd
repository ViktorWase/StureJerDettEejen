extends Node2D

var alignment

# from MainDude
enum {
	good,
	neutral,
	evul,
	undefined
}

func is_evul():
	return alignment == evul

func is_good():
	return alignment == good
	
func is_neutral():
	return alignment == neutral

func set_good():
	alignment = good

func set_evul():
	alignment = evul
	
func set_neutral():
	alignment = neutral
# end od MainDude

func _ready():
	set_neutral()
	
	$fire.hide()

func is_character_nearby():
	var tilemap = get_parent()
	var has_character = false
	for y in range(3):
		for x in range(3):
			var obj = tilemap.get_obj_from_tile()
			if (obj and obj.is_good()):
				return true
	return false
