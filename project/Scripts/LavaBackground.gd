extends TextureRect

var time = 0

func _physics_process(delta):
	time += delta
	material.set_shader_param("time", time)
