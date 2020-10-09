extends "res://Enemy.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	max_walk_distance = 2
	damage = 1
	can_walk_on_lava = false
	attack_coordinates = [[0, 1], [1, 0], [-1, 0], [0, -1]]

	max_hp = 2
	current_hp = 2
