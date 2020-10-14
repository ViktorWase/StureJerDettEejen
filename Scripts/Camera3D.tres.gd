extends Camera

var tile

func _ready():
	tile = get_parent().get_node("tile")

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

	var space_state = get_world().direct_space_state
	
	var dir = project_ray_normal(mouse)

	var result = space_state.intersect_ray(transform.origin, dir*1000, [self], 2, false, true)

	if result:
		var p = result.position
		p.y = 0.01
		p.x = floor(p.x)+0.5
		p.z = floor(p.z)+0.5
		tile.transform.origin = p
