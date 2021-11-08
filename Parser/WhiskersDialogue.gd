class_name WhiskersDialogue extends Reference

var display_name = ""
var name = ""
var data = {}

var previous_node_name
var current_node_name


func _init(path: String):
	open_whiskers(path)


func _get_start_node_name() -> String:
	var start_nodes: Dictionary = get_nodes_by_type("start")
	match(start_nodes.size()):
		0:
			print("[ERROR]: whiskers file has no Start node!")
			return ""
		1: 
			return start_nodes.keys()[0]
			
	print("[WARNING]: there is more than one Start node. The first found will be used.")
	return start_nodes.keys()[0]


func _parse_data(node_name: String, output_slot: int = 0):
	var node_output = data[node_name]["connections"]["output"]
	var next_node = node_output.get(str(output_slot))
	
	if not next_node:
		print("[ERROR]: node does not have an output slot: " + str(output_slot))
		return {}
	
	if next_node.size() == 0:
		print("Reached deadend of dialogue")
		return {
			"is_deadend": true
		}
		
	previous_node_name = node_name
	current_node_name = next_node[0]["name"]
	
	var current_node = data[current_node_name]
	
	return {
		"type": current_node["type"],
		"text": current_node["text"],
		"node_data": current_node["node_data"],
		"is_deadend": false
	}


func open_whiskers(path: String) -> void:
	var file = File.new()
	
	var error = file.open(path, File.READ)
	if error:
		print("[ERROR]: couldn't open file at %s. Error number %s." % [path, error])
		data = {}
		return
	
	var dialogue_data = parse_json(file.get_as_text())
	file.close()
	
	if not dialogue_data is Dictionary:
		print("[ERROR]: failed to parse whiskers file. Is it a valid exported whiskers file?")
		data = {}
		return
	
	data = dialogue_data["nodes"]
	
	var info = dialogue_data.get("info")
	if not info:
		print("[WARNING]: whiskers file does not have an info tab")
		return
		
	display_name = info.get("display_name", "")
	name = info.get("name", "")


func get_nodes_by_type(type: String) -> Dictionary:
	var nodes = {}
	for node_name in data:
		if type == data[node_name].get("type"):
			nodes[node_name] = data[node_name]
	
	return nodes


func start():
	var start_node_name = _get_start_node_name()
	if not start_node_name:
		return {}
	
	return _parse_data(start_node_name, 0)


func next(selection: int = 0):
	return _parse_data(current_node_name, selection)
