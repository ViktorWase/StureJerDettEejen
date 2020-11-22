extends Camera

var tile
var tilemap

func _ready():
	tile = get_parent().get_node("tile")
	
	var cells = get_parent().get_node("TileMap").get_used_cells()
	
	get_parent().get_node("TileMap").connect("ready", self, "_on_TileMap_ready")

func _on_TileMap_ready(_tilemap):
	tilemap = _tilemap

func _input(event):
	if event is InputEventMouseButton:
		if not event.is_pressed():
			return
		
		var zoom_pos = 0
		if event.button_index == BUTTON_WHEEL_UP:
			zoom_pos = -1
		if event.button_index == BUTTON_WHEEL_DOWN:
			zoom_pos = 1
		
		transform.origin += transform.basis.z*zoom_pos*2

func _physics_process(delta):
	var mouse = get_viewport().get_mouse_position()

	var coord = get_tile_from_screen(mouse)

	if coord:
		tile.transform.origin = Vector3(coord.x+0.5, 0.01, coord.y+0.5)

func get_tile_from_screen(screen_pos : Vector2):
	var mouse = get_viewport().get_mouse_position()

	var space_state = get_world().direct_space_state
	
	var dir = project_ray_normal(screen_pos)

	var result = space_state.intersect_ray(transform.origin, dir*1000, [self], 2, false, true)

	if result:
		var coord = Vector2(floor(result.position.x), floor(result.position.z))
		return coord
	return null

# Converts mouse position to world coordinates.
func world_to_map(event):
	var coord = get_tile_from_screen(event.position)
	var offset = Vector2(tilemap.offsetX, tilemap.offsetY)
	return coord - offset
