extends Node

# If true, you can stand on it.
var walkable = true

# If true, then this affects the entire team. If false, it affects the
# character that picked it up.
var is_for_all = true

# If true, then the effect happens once (on pickup).
# If false, it is something that has to carried.
var is_a_one_time_thing = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func is_item():
	return true

func is_evul():
	return false

func is_good():
	return false

func on_pickup(character, flat_game_board):
	assert(false, "You picked up an abstract base class, you dumdum.")

# This function is called after the character who carries the object has moved
# and possibly attacked.
func after_being_moved(character, flat_game_board):
	assert(false, "You moved an abstract base class, you dumdum.")
