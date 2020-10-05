extends Node2D

signal end_turn_pressed()
signal restart_pressed()

var time = 0

func _ready():
	hide_ripples_effect()

func _physics_process(delta):
	time += delta
	$Ripples.material.set_shader_param("time", time)

func show_ripples_effect():
	$Ripples.show()

func hide_ripples_effect():
	$Ripples.hide()

func play_menu_sound():
	$MenuSound.play()

func _on_Button_pressed():
	emit_signal("end_turn_pressed")

func _on_RestartButton_pressed():
	emit_signal("restart_pressed")
