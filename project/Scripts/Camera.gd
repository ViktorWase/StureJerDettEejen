extends Camera2D


var imageSize = Vector2(128, 128)
var tileMap = null
export var cameraPanScale = 2
export var cameraPanSpeed = 2
var targetPos = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	make_current()
	targetPos = get_viewport().size/2
	pass # Replace with function body.


func _physics_process(delta):
	if not tileMap:
		return
	
	var viewportSize = get_viewport().size
	var levelSize = Vector2(tileMap.width, tileMap.height)*tileMap.tileSize
	var pos = get_viewport().get_mouse_position()
	
	# square rect for now
	var viewRect = Rect2(
		viewportSize.x/2 - levelSize.x/2,
		viewportSize.y/2 - levelSize.y/2,
		levelSize.x,
		levelSize.y
	)
	
#	if pos.x < tileMap.position.x:
#		pos.x = tileMap.position.x
#	if pos.x > viewportSize.x/2+levelSize.x/2:
#		pos.x = viewportSize.x/2+levelSize.x/2
#	if pos.y < tileMap.position.y:
#		pos.y = tileMap.position.y
#	if pos.y > viewportSize.y/2+levelSize.y/2:
#		pos.y = viewportSize.y/2+levelSize.y/2

	var pan = Vector2.ZERO

	if not viewRect.has_point(pos):
		var dir = pos - viewportSize/2
		# "length - radius" kind of
		targetPos = position + dir.normalized()*(dir.length()-viewRect.size.x/2)*cameraPanScale
		
		if targetPos.x < tileMap.position.x:
			targetPos.x = tileMap.position.x
		if targetPos.x > viewportSize.x/2+levelSize.x/2:
			targetPos.x = viewportSize.x/2+levelSize.x/2
		if targetPos.y < tileMap.position.y:
			targetPos.y = tileMap.position.y
		if targetPos.y > viewportSize.y/2+levelSize.y/2:
			targetPos.y = viewportSize.y/2+levelSize.y/2

#	if pos.x < viewRect.position.x:
#		pan.x = -pow((viewRect.position.x - pos.x) / viewRect.position.x, 2)
#	if pos.x > viewRect.end.x:
#		pan.x = pow((pos.x - viewRect.end.x) / (viewportSize.x - viewRect.end.x), 2)
#	if pos.y < viewRect.position.y:
#		pan.y = -pow((viewRect.position.y - pos.y) / viewRect.position.y, 2)
#	if pos.y > viewRect.end.y:
#		pan.y = pow((pos.y - viewRect.end.y) / (viewportSize.y - viewRect.end.y), 2)

#	if pos.x < viewRect.position.x:
#		pan.x = -(viewRect.position.x - pos.x) / viewRect.position.x
#	if pos.x > viewRect.end.x:
#		pan.x = (pos.x - viewRect.end.x) / (viewportSize.x - viewRect.end.x)
#	if pos.y < viewRect.position.y:
#		pan.y = -(viewRect.position.y - pos.y) / viewRect.position.y
#	if pos.y > viewRect.end.y:
#		pan.y = (pos.y - viewRect.end.y) / (viewportSize.y - viewRect.end.y)
	
	# target
	#pos = position + pan*cameraPanScale
	# interpolation
	pos = position + (targetPos - position)*cameraPanSpeed*delta
	
	position = pos
	
	# (size/imageSize)*(pos/size) = pos/imageSize
	$LavaBackground.material.set_shader_param("offset", pos/imageSize)
	
	# TODO: prettify
	get_parent().get_node("GUI").position = position - viewportSize/2


func _on_TileMap_ready(tileMap):
	print("tilemap ready")
	self.tileMap = tileMap
