extends "res://GoodCharacter.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	#$AnimatedSprite.play("idle")
	max_walk_distance = 3
	max_hp = 1
	current_hp = 1
	damage = 1
	attack_coordinates = [Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0), Vector2(0, -1)]

func play_idle():
	$AnimatedSprite.play("idle")

func play_run():
	$AnimatedSprite.play("run")
