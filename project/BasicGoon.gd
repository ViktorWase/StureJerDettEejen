extends "res://EvulCharacter.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	max_walk_distance = 2
	max_watch_distance = 3
	personality = BattlePersonality.attackRandomlyOnlyIfItSeesAGoodGuy
	damage = 1
	can_walk_on_lava = false
	attack_coordinates = [[0, 1], [1, 0], [-1, 0], [0, -1]]

	max_hp = 1
	current_hp = max_hp
