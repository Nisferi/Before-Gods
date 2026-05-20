extends Node

func _ready() -> void:
	EventBus.scene_transition_requested.connect(_on_scene_transition)
	_start()

func _start() -> void:
	if SaveSystem.has_save():
		SaveSystem.load_save()
	# TODO: transition to main menu or map scene

func _on_scene_transition(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
