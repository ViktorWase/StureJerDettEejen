extends Node

var levels = [
	"easy1",
	"easy2",
	"Level_1",
	"middle_armor",
	"Level_2",
	"battlefield"
]
var level_index = -1

func _ready():
	print("from global")

func load_next_level():
	level_index += 1
	if (level_index >= len(levels)):
		get_tree().change_scene("res://GameEnd.tscn")
		return
	
	get_tree().change_scene("res://Levels/"+levels[level_index]+".tscn")

func restart_game():
	level_index = -1
	get_tree().change_scene("res://GameStart.tscn")
