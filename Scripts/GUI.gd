extends Node2D

signal end_turn_pressed()
signal restart_pressed()

func _on_Button_pressed():
	emit_signal("end_turn_pressed")

func _on_RestartButton_pressed():
	emit_signal("restart_pressed")
