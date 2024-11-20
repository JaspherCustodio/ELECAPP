extends KinematicBody2D

var vote = 0 setget set_vote
var velocity = Vector2(0,0)
var can_vote = true
var max_votes = 3
var current_votes = 0

var username_text = load("res://UsernameText.tscn")

var username setget username_set
var username_text_instance = null

puppet var puppet_vote = 0 setget puppet_vote_set
puppet var puppet_position = Vector2(0, 0) setget puppet_position_set
puppet var puppet_username = "" setget puppet_username_set

onready var tween = $Tween
onready var vote_button = $VoteButton
onready var vote_label = $VoterLabel


func _ready():
	get_tree().connect("network_peer_connected", self, "_network_peer_connected")
	
	username_text_instance = Global.instance_node_at_location(username_text, PersistentNodes, global_position)
	username_text_instance.player_following = self
	
	update_vote_mode(false)
	update_vote_label()
	Global.alive_player.append(self)
	
	yield(get_tree(), "idle_frame")
	if get_tree().has_network_peer():
		if is_network_master():
			Global.player_master = self

func _process(_delta: float) -> void:
	if username_text_instance != null:
		username_text_instance.name = "username" + name

func puppet_position_set(new_value) -> void:
	if get_tree().has_network_peer():
		if is_network_master():
			puppet_position = new_value
			
			tween.interpolate_property(self, "global_position", global_position, puppet_position, 0.1)
			tween.start()

func set_vote(new_value):
	vote = new_value
	if get_tree().has_network_peer():
		if is_network_master():
			rset("puppet_vote", vote)

func puppet_vote_set(new_value):
	puppet_vote = new_value
	if get_tree().has_network_peer():
		if not is_network_master():
			vote = puppet_vote

func username_set(new_value) -> void:
	username = new_value
	
	if get_tree().has_network_peer():
		if is_network_master() and username_text_instance != null:
			username_text_instance.text = username
			rset("puppet_username", username)

func puppet_username_set(new_value) -> void:
	puppet_username = new_value
	if get_tree().has_network_peer():
		if not is_network_master() and username_text_instance != null:
			username_text_instance.text = puppet_username

func _network_peer_connected(id) -> void:
	rset_id(id, "puppet_username", username)

func _on_NetworkTickRate_timeout():
	if get_tree().has_network_peer():
		if is_network_master():
			rset_unreliable("puppet_position", global_position)
			rset_unreliable("puppet_position", velocity)

sync func update_position(pos):
	global_position = pos
	puppet_position = pos

func _on_VoteButton_pressed(player):
	if get_tree().is_network_server() and can_vote:
		if current_votes < max_votes:
			PersistentNodes.get_children()[player] += 1
			current_votes += 1
			update_vote_label()
			if current_votes == max_votes:
				end_voting()
		else:
			 print("Maximum votes reached!")

func reset_votes():
	current_votes = 0
	vote_button.disabled = false
	update_vote_label()

sync func update_vote_label():
	vote_label.text = "Votes: %d/%d\n" % [current_votes, max_votes]

func update_vote_mode(vote_mode):
	if not vote_mode:
		vote_button.hide()
		vote_label.hide()
	else:
		vote_button.show()
		vote_label.show()
	
	can_vote = vote_mode

sync func destroy() -> void:
	username_text_instance.visible = false
	visible = false
	Global.alive_player.erase(self)
	
	if get_tree().has_network_peer():
		if is_network_master():
			Global.player_master = null

sync func end_voting():
	for button in PersistentNodes.get_children():
		button.disabled = true
		var max_vote = 0
		var player_to_destroy = null
		for player in PersistentNodes.get_children():
			if PersistentNodes.get_children()[player] > max_vote:
				max_vote = PersistentNodes.get_children()[player]
				player_to_destroy = player
		
		if player_to_destroy:
			print("%s has been destroyed!" % player_to_destroy)
			if username_text_instance != null:
				username_text_instance.visible = false
			
			if get_tree().is_network_server():
					rpc("destroy")

func _exit_tree() -> void:
	Global.alive_player.erase(self)
	if get_tree().has_network_peer():
		if is_network_master():
			Global.player_master = null
