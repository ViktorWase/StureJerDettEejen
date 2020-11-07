extends Camera2D


export var panPadding = Vector2(50, 50)
export var viewportPadding = Vector2(150, 150)
export var cameraPanScale = 2
export var cameraPanSpeed = 2

var imageSize = Vector2(128, 128)
var tileMap = null
var targetPos = Vector2.ZERO

var viewportSize : Vector2
var levelSize : Vector2
var panRect : Rect2
var viewportRect : Rect2

# Called when the node enters the scene tree for the first time.
func _ready():
	make_current()
	targetPos = get_viewport().size/2
	
	get_parent().get_node("TileMap").connect("ready", self, "_on_TileMap_ready")


func _physics_process(delta):
	if not tileMap:
		return

	var mousePos = get_viewport().get_mouse_position()

	if not panRect.has_point(mousePos):
		updatePan(mousePos)
	
	# interpolation
	var pos = position + (targetPos - position)*cameraPanSpeed*delta
	
	# update camera position
	position = pos.round()
	
	# (size/imageSize)*(pos/size) = pos/imageSize
	$LavaBackground.material.set_shader_param("offset", pos/imageSize)
	
	# TODO: prettify
	get_parent().get_node("GUI").position = position - viewportSize/2

func updatePan(pos):
	# get pan speed and direction
	var dir = (pos - viewportSize/2).normalized()
	var panAmount = 0
	if pos.x < panPadding.x || pos.x > panPadding.x + panRect.size.x:
		if dir.x > 0:
			panAmount = pos.x -viewportSize.x/2- panRect.size.x/2
		else:
			panAmount = - (pos.x -viewportSize.x/2)- panRect.size.x/2
		panAmount /= panPadding.x
	else:
		if dir.y > 0:
			panAmount = pos.y -viewportSize.y/2- panRect.size.y/2
		else:
			panAmount = - (pos.y - viewportSize.y/2) - panRect.size.y/2
		panAmount /= panPadding.y
	
	# avoid negative values
	panAmount = max(0, panAmount)
	
	# set target
	targetPos = position + dir*(0.2 + panAmount/0.8)*cameraPanScale
	
	# calculate limits
	if levelSize.x > viewportRect.size.x:
		if targetPos.x - viewportRect.size.x/2 < tileMap.position.x:
			targetPos.x = tileMap.position.x + viewportRect.size.x/2
		
		if targetPos.x + viewportRect.size.x/2 > tileMap.position.x+levelSize.x:
			targetPos.x = tileMap.position.x+levelSize.x - viewportRect.size.x/2
	else:
		# place in the middle
		targetPos.x = tileMap.position.x+levelSize.x/2
	
	if levelSize.y > viewportRect.size.y:
		if targetPos.y - viewportRect.size.y/2 < tileMap.position.y:
			targetPos.y = tileMap.position.y + viewportRect.size.y/2
		
		if targetPos.y + viewportRect.size.y/2 > tileMap.position.y+levelSize.y:
			targetPos.y = tileMap.position.y+levelSize.y - viewportRect.size.y/2
	else:
		# place in the middle
		targetPos.y = tileMap.position.y+levelSize.y/2

func world_to_map(event):
	var offset = position - viewportSize/2
	var pos = tileMap.world_to_map(event.position - (tileMap.position - offset))
	return pos

func _on_TileMap_ready(tileMap):
	self.tileMap = tileMap

	viewportSize = get_viewport().size
	levelSize = Vector2(tileMap.width, tileMap.height)*tileMap.tileSize
	panRect = Rect2(0, 0, viewportSize.x, viewportSize.y).grow_individual(-panPadding.x, -panPadding.y, -panPadding.x, -panPadding.y)
	viewportRect = Rect2(0, 0, viewportSize.x, viewportSize.y).grow_individual(-viewportPadding.x, -viewportPadding.y, -viewportPadding.x, -viewportPadding.y)

	# init pan to top left
	updatePan(Vector2(0, 0))
	# avoid rendering glitches
	position = targetPos.round()
