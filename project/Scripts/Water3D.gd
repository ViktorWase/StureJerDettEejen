extends MeshInstance

var time = 0

func _physics_process(delta):
	time += delta
	get_surface_material(0).set_shader_param("time", time)
