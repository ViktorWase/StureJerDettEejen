# Implements a main Camera that overrides the default viewport.
#
# The camera allows for bigger levels to be displayed with the same zoom level
# by making the level pannable with mouse input.
# The panning behaviour is managed with two virtual boxes and two speed
# constants.
#
# Area A to the viewport edges, defined by padding_pan, defines the area where
# mouse input pans.
# Area B, defined by padding_viewport, defines the min and max distance between
# the level edges and the viewport edges.
# ___________________________________
# | A_____________________________  |
# |  | B_______________________  |  |
# |  |  |                      |  |  |
# |  |  |                      |  |  |
# |  |  |                      |  |  |
# |  |  |_____________________|  |  |
# |  |___________________________|  |
# |_________________________________|
extends Camera2D

# area from the viewport edges where the mouse pans
var padding_pan = Vector2(50, 50)
# distance between the level edges and the viewport edges
var padding_viewport = Vector2(150, 150)
# panning speed
var speed_pan = 160
# panning acceleration/easing (not physically correct)
var acc_pan = 2

var tilemap = null
# camera target position
var pos_target = Vector2.ZERO
# backgound image size (TODO: maybe fetch this from the resource)
var size_background_image = Vector2(640, 640)

var size_viewport : Vector2
var size_level : Vector2
var rect_pan : Rect2
var rect_viewport : Rect2

# Called when the node enters the scene tree for the first time.
func _ready():
	make_current()
	pos_target = get_viewport().size/2
	
	get_parent().get_node("TileMap").connect("ready", self, "_on_TileMap_ready")


func _physics_process(delta):
	if not tilemap:
		return

	var pos_mouse = get_viewport().get_mouse_position()

	# Only pan if we are in the panning area (in the padding_pan)
	if not rect_pan.has_point(pos_mouse):
		updatePan(pos_mouse)
	
	# interpolation
	var pos = position + (pos_target - position)*acc_pan*delta
	
	# update camera position
	# avoid render glitches by rounding to whole pixels
	position = pos.round()
	
	# mirror panning in the background shader
	$WaterBackground.material.set_shader_param("offset", pos/size_background_image)
	
	# move the GUI (TODO: would be nice to have the GUI be a child to the
	# camera but still visible on top)
	get_parent().get_node("GUI").position = position - size_viewport/2


# Sets a new target position for the camera based on mouse input.
# Input a Vector.ZERO to pan to the upper left e.g.
func updatePan(pos):
	# get pan speed and direction
	var dir = (pos - size_viewport/2).normalized()
	var speed_normalized = 0
	if pos.x < padding_pan.x || pos.x > padding_pan.x + rect_pan.size.x:
		if dir.x > 0:
			speed_normalized = pos.x -size_viewport.x/2- rect_pan.size.x/2
		else:
			speed_normalized = - (pos.x -size_viewport.x/2)- rect_pan.size.x/2
		speed_normalized /= padding_pan.x
	else:
		if dir.y > 0:
			speed_normalized = pos.y -size_viewport.y/2- rect_pan.size.y/2
		else:
			speed_normalized = - (pos.y - size_viewport.y/2) - rect_pan.size.y/2
		speed_normalized /= padding_pan.y
	
	# avoid negative values
	speed_normalized = max(0, speed_normalized)
	
	# set target by using speed_pan and a little interaction easing (speed
	# starts at 0.2)
	pos_target = position + dir*(0.2 + speed_normalized/0.8)*speed_pan
	
	# calculate limits with rect_viewport (area B)
	# calculate pan limits for x-axis
	if size_level.x > rect_viewport.size.x:
		if pos_target.x - rect_viewport.size.x/2 < tilemap.position.x:
			pos_target.x = tilemap.position.x + rect_viewport.size.x/2
		
		if pos_target.x + rect_viewport.size.x/2 > tilemap.position.x+size_level.x:
			pos_target.x = tilemap.position.x+size_level.x - rect_viewport.size.x/2
	else:
		# place in the middle if the level fits within the virtual viewport
		pos_target.x = tilemap.position.x+size_level.x/2
	
	# calculate pan limits for y-axis
	if size_level.y > rect_viewport.size.y:
		if pos_target.y - rect_viewport.size.y/2 < tilemap.position.y:
			pos_target.y = tilemap.position.y + rect_viewport.size.y/2
		
		if pos_target.y + rect_viewport.size.y/2 > tilemap.position.y+size_level.y:
			pos_target.y = tilemap.position.y+size_level.y - rect_viewport.size.y/2
	else:
		# place in the middle if the level fits within the virtual viewport
		pos_target.y = tilemap.position.y+size_level.y/2


# Converts mouse position to world coordinates.
func world_to_map(event):
	var offset = position - size_viewport/2
	var pos = tilemap.world_to_map(event.position - (tilemap.position - offset))
	return pos


# Called from the TileMap ready function
func _on_TileMap_ready(tilemap):
	self.tilemap = tilemap

	size_viewport = get_viewport().size
	size_level = Vector2(tilemap.width, tilemap.height)*tilemap.tileSize
	rect_pan = Rect2(0, 0, size_viewport.x, size_viewport.y).grow_individual(-padding_pan.x, -padding_pan.y, -padding_pan.x, -padding_pan.y)
	rect_viewport = Rect2(0, 0, size_viewport.x, size_viewport.y).grow_individual(-padding_viewport.x, -padding_viewport.y, -padding_viewport.x, -padding_viewport.y)

	# init pan to top left
	updatePan(Vector2(0, 0))
	# avoid rendering glitches
	position = pos_target.round()
