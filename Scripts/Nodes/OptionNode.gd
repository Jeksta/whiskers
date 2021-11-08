extends BaseGraphNode


var entry_template = preload("res://Scenes/OptionNodeEntry.tscn")


func _ready():
	._ready()
	
	var add_button = get_node("AddButton")
	add_button.connect("pressed", self, "_on_Button_pressed")
	
	get_node("Entry/Entry/DeleteButton").visible = false



func _on_Button_pressed():
	add_entry()


func _on_Entry_deleted():
	set_slot(get_child_count() - 1, false, 0, ColorN("white"), false, 0, ColorN("white"))


func add_entry(value = ""):
	var new_entry = entry_template.instance()
	var delete_button = new_entry.get_node("Entry/DeleteButton")
	# child removes itself
	delete_button.connect("pressed", new_entry, "queue_free")
	new_entry.connect("tree_exited", self, "_on_Entry_deleted")
	
	new_entry.get_node("Entry/LineEdit").text = value
	
	var child_count = get_child_count()
	add_child_below_node(get_child(child_count - 2), new_entry)
	set_slot(child_count - 1, false, 0, ColorN("white"), true, 0, ColorN("white"))


func serialize():
	return ._serialize("option")


func set_node_data(node_data):
	for i in node_data["data"]:
		match(i):
			"0":
				get_node("Entry/Entry/LineEdit").text = node_data["data"][i]
			_:
				add_entry(node_data["data"][i])


func get_node_data():
	var data = .get_node_data()
	data["type"] = "array"
	for i in range(get_child_count() - 1):
		var entry = get_child(i)
		
		if not entry is VBoxContainer:
			continue
		
		data["data"][i] = entry.get_node("Entry/LineEdit").text
		 
	return data


func set_text(val):
	pass


func get_text():
	return ""
