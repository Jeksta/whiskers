extends BaseGraphNode

var entry_template = preload("res://Scenes/DataNodeEntry.tscn")


func _ready():
	._ready()
	
	var type_button = get_node("HBoxContainer/VBoxContainer/TypeOption")
	var add_button = get_node("HBoxContainer/AddButton")
	
	type_button.connect("item_selected", self, "_on_OptionButton_item_selected")
	add_button.connect("pressed", self, "_on_Button_pressed")


func _on_OptionButton_item_selected(index):
	match(index):
		0:	# Array
			_set_keys_visible(false)
		1:	# Dictionary
			_set_keys_visible(true)


func _on_Button_pressed():
	add_entry()


func _on_Entry_deleted():
	var lines = get_node("Lines")
	for i in range(lines.get_child_count()):
		var entry = lines.get_child(i)
		entry.get_node("Index").text = str(i)


func _set_keys_visible(val):
	for entry in get_node("Lines").get_children():
		entry.get_node("Data/Key").visible = val


func add_entry(key = "", value = ""):
	var new_entry = entry_template.instance()
	var delete_button = new_entry.get_node("DeleteButton")
	# child removes itself
	delete_button.connect("pressed", new_entry, "queue_free")
	# reassign indexes
	new_entry.connect("tree_exited", self, "_on_Entry_deleted")
	
	var index = get_node("Lines").get_child_count()
	new_entry.get_node("Index").text = str(index)
	
	match(get_node("HBoxContainer/VBoxContainer/TypeOption").selected):
		0:	# Array
			new_entry.get_node("Data/Key").visible = false
		1:	# Dictionary
			new_entry.get_node("Data/Key").visible = true
	
	new_entry.get_node("Data/Key").text = key
	new_entry.get_node("Data/Value").text = value
	
	get_node("Lines").add_child(new_entry)


func serialize():
	return ._serialize("data")


func set_node_data(node_data):
	var type_option = get_node("HBoxContainer/VBoxContainer/TypeOption")
	var data_type = node_data["type"]
	var data = node_data["data"]

	# set data type
	match(data_type):
		"array":
			type_option.selected = 0
		"dictionary":
			type_option.selected = 1
	
	# set entries from data
	for key in data:
		match(type_option.selected):
			0:	# Array
				add_entry("", data[key])
			1:	# Dictionary
				add_entry(key, data[key])
	


func get_node_data():
	var data = .get_node_data()

	var data_type = get_node("HBoxContainer/VBoxContainer/TypeOption").selected
	match(data_type):
		0:	# Array
			data["type"] = "array"
		1:	# Dictionary
			data["type"] = "dictionary"
	
	var i = 0
	for entry in get_node("Lines").get_children():
		var key 
		match(data_type):
			0:	# Array
				key = i
			1:	# Dictionary
				key = entry.get_node("Data/Key").text
				
		data["data"][key] = entry.get_node("Data/Value").text
		
		i += 1
	
	return data


func set_text(val):
	get_node("HBoxContainer/VBoxContainer/Description").text = val


func get_text():
	return get_node("HBoxContainer/VBoxContainer/Description").text
