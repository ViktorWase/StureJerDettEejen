extends Sprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func on_click(idx):
	print("YOU CLICKED THE MAIN DUDE")
	var x = self.get_parent().flat_to_xy(idx)[0]
	var y = self.get_parent().flat_to_xy(idx)[1]
	self.get_parent().place_green_tiles(x,y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
