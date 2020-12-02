extends Sprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


var cx : int = 0
var cy : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("green tiles")


func set_coordinates(coord):
	# kolla om vi får ett fel, hälsningar Intrud
	cx = coord.x
	cy = coord.y

	var tilemap = get_parent().get_parent()
	position.x = tilemap.map_to_world(coord)[0] + 16
	position.y = tilemap.map_to_world(coord)[1] + 16

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
