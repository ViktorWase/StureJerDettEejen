extends Sprite3D


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

	var tilemap = get_parent()	
	transform.origin.x = coord.x + tilemap.offsetX + 0.5
	transform.origin.y = 0.01
	transform.origin.z = coord.y + tilemap.offsetY + 0.5

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
