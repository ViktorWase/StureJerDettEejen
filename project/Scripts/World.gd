tool
extends Spatial

export var show_grid = true setget set_show_grid

func set_show_grid(show):
	if show:
		$grid.show()
	else:
		$grid.hide()
	show_grid = show
