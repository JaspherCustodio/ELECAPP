extends Control


func _on_OK_pressed():
	get_tree().change_scene("res://Scenes/NetworkSetup.tscn")

func set_text(text) -> void:
	$Label.text = text
