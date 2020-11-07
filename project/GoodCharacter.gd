extends "res://Character.gd"

# TODO: Maybe enemies should be able to take items too? I don't think so, but maybe the smart ones.
var items = []

# Called when the node enters the scene tree for the first time.
func _ready():
	set_good()
	add_to_group("Characters")  # TODO: Did I rename it to good guys or something?

func set_target_pickup(item, flat_game_board):
	# This function is called when an item is picked up.
	# TODO: Actually, this function is called when a good guy STARTS walking to
	# an item, not when they arrive at it. Fix this, otherwise we might get some
	# strange bugs.
	var should_be_carried = (not item.is_for_all) and (not item.is_a_one_time_thing)

	# The effect is a sound or animation that should be played.
	# TODO: WE DON'T HAVE SUPPORT FOR THAT YET!
	var effect = item.on_pickup(self, flat_game_board)

	if should_be_carried:
		items.append(item)

	var result_dict = {}
	if effect:
		result_dict["effect"] = effect

	var should_be_added_to_global_item_list = item.is_for_all and (not item.is_a_one_time_thing)
	if should_be_added_to_global_item_list:
		result_dict["to_global_item_list"] = item

	return result_dict


func go_thru_all_items_after_turn(flat_game_board):
	var effects = []  # Some effects need animations or sounds or stuff. TODO: Add an effect class?
	for item in items:
		var effect = item.after_being_moved(self, flat_game_board)
		if effect:
			effects.append(effect)
	return effects
