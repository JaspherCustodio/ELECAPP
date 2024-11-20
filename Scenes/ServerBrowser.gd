extends Control


onready var server_listener = $ServerListener
onready var server_ip_text_edit = $ServerTextEdit
onready var server_container = $VBoxContainer
onready var manual_setup_button = $ManualSetup

func _ready() -> void:
	server_ip_text_edit.hide()

func _on_ServerListener_new_server(serverInfo):
	var server_node = Global.instance_node(load("res://Scenes/ServerDisplay.tscn"), server_container)
	server_node.text = "%s - %s" % [serverInfo.ip, serverInfo.name]
	server_node.ip_address = str(serverInfo.ip)

func _on_ServerListener_remove_server(serverIP):
	for serverNode in server_container.get_children():
		if serverNode.is_in_group("server_display"):
			if serverNode.ip_address == serverIP:
				serverNode.queue_free()
				break

func _on_ManualSetup_pressed():
	if manual_setup_button.text != "EXIT SETUP":
		server_ip_text_edit.show()
		manual_setup_button.text = "EXIT SETUP"
		server_container.hide()
		server_ip_text_edit.call_deferred("grab_focus")
	else:
		server_ip_text_edit.text = ""
		server_ip_text_edit.hide()
		manual_setup_button.text = "MANUAL SETUP"
		server_container.show()

func _on_JoinServer_pressed():
	Network.ip_address = server_ip_text_edit.text
	hide()
	Network.join_server()

func _on_GoBack_pressed():
	get_tree().reload_current_scene()
