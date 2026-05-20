extends Node

func _ready() -> void:
	if SaveSystem.has_save():
		SaveSystem.load_save()
	get_tree().change_scene_to_file.call_deferred("res://scenes/world/map_scene.tscn")
