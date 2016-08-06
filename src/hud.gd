extends Control

onready var life_node = get_node("hp")
onready var damage_node = get_node("hp/red_hp")
onready var stamina_node = get_node("stamina")
onready var names_node = get_node("names")
onready var players_list_node = get_node("players_list")

var local_player
var other_players = []
var ray_exceptions = []
var camera_node

func init(local_player):
	self.local_player = local_player.get_node("body")
	self.local_player.connect("got_item", self, "_on_got_item")
	self.local_player.connect("used_item", self, "_on_used_item")
	update_items()
	camera_node = get_viewport().get_camera()

	ray_exceptions.append(self.local_player)

	var label = new_label(local_player.get_name())
	var pos = camera_node.unproject_position(self.local_player.get_node("name").get_global_transform().origin)
	var size = label.get_size()
	label.set_pos(pos - Vector2(size.x/2, size.y/2))

func _ready():
	set_fixed_process(true)
	set_process_input(true)

func _input(event):
	if networking.multiplayer:
		if event.is_action_pressed("players_list"):
			players_list_node.show()
		elif event.is_action_released("players_list"):
			players_list_node.hide()
	if event.is_action_pressed("player_scroll_next") or event.is_action_pressed("player_scroll_back"):
		update_items()

func _fixed_process(delta):
	update_values()
	if networking.multiplayer and other_players.size() > 0:
		update_names()

func player_connected(player_name):
	new_label(player_name)
	var p = get_node("../player_spawn/" + player_name + "/body")
	other_players.append(p)
	ray_exceptions.append(p)

func player_disconnected(player_name):
	var p = get_node("../player_spawn/" + player_name + "/body")
	other_players.erase(p)
	ray_exceptions.erase(p)
	names_node.get_node(player_name).queue_free()

func new_label(name):
	var label = Label.new()
	label.set_name(name)
	label.set_text(name)
	names_node.add_child(label)
	return label

func update_values():
	life_node.set_value(local_player.hp)
	damage_node.set_value(local_player.regenerable_hp)
	stamina_node.set_value(local_player.stamina)

func update_items():
	var i = -2
	for child in get_node("items_bar").get_children():
		if child extends Panel:
			var item = local_player.items[(local_player.active_item + i) % local_player.items.size()]
			child.get_node("icon").set_texture(item.icon)
			i += 1
	var item = local_player.items[local_player.active_item]
	get_node("items_bar/quantity/label").set_text(str(item.quantity))
	get_node("items_bar/name/label").set_text(item.name)

func update_names():
	var local_player_pos = local_player.camera_node.get_global_transform().origin
	var space_state = get_node("/root/game").get_world().get_direct_space_state()
	for player in other_players:
		var name = player.get_name()
		var player_pos = player.get_node("name").get_global_transform().origin
		var label = names_node.get_node(name)
		if camera_node.is_position_behind(player_pos):
			label.hide()
		else:
			# use global coordinates, not local to node
			var result = space_state.intersect_ray(local_player_pos, player_pos, ray_exceptions)
			if not result.empty():
				label.hide()
			else:
				label.show()
				var pos = camera_node.unproject_position(player_pos)
				var size = label.get_size()
				label.set_pos(pos - Vector2(size.x/2, size.y/2))

func _on_got_item(item):
	var label = get_node("itemget/label")
	label.set_text("You got %s" % item.name)
	get_node("itemget/animation").play("show")
	update_items()

func _on_used_item(item):
	update_items()
