extends GraphEdit

var lastNodePosition = Vector2(0,0)
var open = false
var preFire = false
var timer = 0
var path = ''

func _ready():
	get_node("../../../../Modals/Save").connect("file_selected", self, "_save_whiskers")
	get_node("../../../../Modals/Open").connect("file_selected", self, "pre_open")
	get_node("../../../../Modals/Import").connect("file_selected", self, "_import_singleton")


func get_connections(name):
	var list = get_connection_list()
	var connections = {}
	
	for i in range(0, list.size()):
		if name in list[i]['to']:
			connections[connections.size() + 1] = list[i]['from']
	
	return connections

# this is really ugly
# but I can't figure out a way to get our GraphEdit to redraw on command
# so until I can, this very ugly hack will have to do.
# it has next to zero impact on performance,
# but it's just so ugly!
func _physics_process(delta):
	self.get_child(0).update()
	self.get_child(1).update()
	if preFire:
		clear_graph()
		clear_connections()
		preFire = false
	if open:
		timer += delta
	if timer > 0.05:
		_open_whiskers(path)
		open = false
		timer = 0

func pre_open(openPath):
	path = openPath
	open = true
	preFire = true

func get_text(from):
	if self.get_node(from).has_node('Lines'):
		return self.get_node(from).get_node('Lines').get_child(0).get_text()
	else:
		return ''

func _on_Dialogue_Graph_connection_request(from, from_slot, to, to_slot):
	connect_node(from, from_slot, to, to_slot)
	var type = EditorSingleton.get_node_type(to)
	EditorSingleton.add_history(type, to, self.get_node(to).get_offset(), get_text(to), get_connections(to), 'connect')

func _on_Dialogue_Graph_disconnection_request(from, from_slot, to, to_slot):
	disconnect_node(from, from_slot, to, to_slot)
	var type = EditorSingleton.get_node_type(to)
	EditorSingleton.add_history(type, to, self.get_node(to).get_offset(), get_text(to), get_connections(to), 'disconnect')

func _on_BasicNodes_item_activated(index):
	if(index == 0):
		init_scene("Dialogue.tscn", false)
	if(index == 1):
		init_scene("Option.tscn", false)
	if(index == 2):
		init_scene("Jump.tscn", false)
	if(index == 3):
		init_scene("Data.tscn", false)
	

func _on_AdvancedNodes_item_activated(index):
	if(index == 0):
		init_scene("Condition.tscn", false)
	if(index == 1):
		init_scene("Expression.tscn", false)

func _on_UtilityNodes_item_activated(index):
	if(index == 0):
		init_scene("Comment.tscn", false)
	if(index == 1):
		init_scene("Start.tscn", false)
	if(index == 2):
		init_scene("End.tscn", false)

func init_scene(e, location):
	var scene = load("res://Scenes/Nodes/"+e)
	var node = scene.instance()
	var offset
	
	if !location:
		offset = Vector2(lastNodePosition.x + 20, lastNodePosition.y + 20)
	else:
		offset = Vector2(location.x, location.y)
	
	get_node("./").add_child(node)
	node.set_offset(offset)
	node.set_name(node.get_name().replace('@', ''))
	
	lastNodePosition = node.get_offset()
	
	#history management
	EditorSingleton.overwrite_history()
	EditorSingleton.add_history(e.split('.tscn')[0], node.name, offset, '', [], 'add')
	
	EditorSingleton.update_stats(node.name, '1')
	
	EditorSingleton.has_graph = true
	
	return node.name


func load_node(type, name, node_data):
	var scene = load("res://Scenes/Nodes/"+type)
	var node = scene.instance()

	get_node("./").add_child(node)

	# load editor stuff
	var editor_data = node_data.get("editor_data")
	if editor_data:
		var location = str(editor_data["location"]).replace('(','').replace(')','').split(',')
		var size = editor_data["size"].split(',')

		node.set_offset(Vector2(location[0], location[1]))
		node.rect_size = Vector2(size[2], size[3])

	node.set_name(name)
	node.set_text(node_data["text"])
	node.set_node_data(node_data["node_data"])


"""
func load_node(type, location, name, text, size):
	var scene = load("res://Scenes/Nodes/"+type)
	var node = scene.instance()
	
	get_node("./").add_child(node)
	location = str(location).replace('(','').replace(')','').split(',')
	node.set_offset(Vector2(location[0], location[1]))
	node.set_name(name)
	if text:
		node.set_text(text)
	if size:
		size = size.split(',')
		node.rect_size = Vector2(size[2], size[3])
	
	EditorSingleton.update_stats(name, '1')
"""

#=======> SAVING
var data = {} # this is the final data, an array of all nodes that we write to file

func process_data():
	var connectionList = get_connection_list()
	# We should save our 'info' tab data!
	data['info'] = {
		'name': get_node("../../Info/Info/Name/Input").get_text(),
		'display_name': get_node("../../Info/Info/DName/Input").get_text(),
	}
	# lets save our GraphNodes!
	for i in range(0, connectionList.size()):
		var name = connectionList[i].from
		# Our schema
		var tempData = {
				'text':"",
				'connects_to':[],
				'logic':"",
				'conditions':{
					'true':'',
					'false':''
				},
				'location':"",
				'size':""
		}
		var currentCTSize = 0
		var currentConnectsTo 
		if name in data:
			currentCTSize = data[name]['connects_to'].size()
			currentConnectsTo = data[name]['connects_to']
		
		# are we a node with a text field?
		if ('Dialogue' in name) or ('Option' in name) or ('Expression' in name) or ('Jump' in name) or ('Comment' in name):
			tempData['text'] = self.get_node(name).get_node('Lines').get_child(0).get_text()
		
		# are we an Expression Node? We should store the value in our logic field
		if ('Expression' in name):
			tempData['logic'] = self.get_node(name).get_node('Lines').get_child(0).get_text()
		
		if ('Condition' in name):
			var routes
			if name in data:
				routes = data[name]['conditions']
			if connectionList[i]['from_port'] == 0:
				tempData['conditions']['true'] = connectionList[i].to
				if (routes) and (routes['false']):
					tempData['conditions']['false'] = routes['false']
			if connectionList[i]['from_port'] == 1:
				tempData['conditions']['false'] = connectionList[i].to
				if (routes) and (routes['true']):
					tempData['conditions']['true'] = routes['true']
		else:
			if currentConnectsTo:
				tempData['connects_to'] = currentConnectsTo
			if not connectionList[i].to in tempData['connects_to']:
				tempData['connects_to'].append(connectionList[i].to)
		
		# store our location
		tempData['location'] = self.get_node(name).get_offset()
		
		# store our size
		tempData['size'] = self.get_node(name).get_rect() 
		
		# are we connecting to an 'End' node?
		if 'End' in connectionList[i].to:
			# we should store the data!
			data[connectionList[i].to] = {
					'text':"",
					'connects_to':{},
					'logic':"",
					'conditions':{},
					'location':self.get_node(connectionList[i].to).get_offset()
			}
		
		# save this in our processed object
		data[name] = tempData


func serialize():
	var save_data = {
		"info": {
			"name": get_node("../../Info/Info/Name/Input").get_text(),
			"display_name": get_node("../../Info/Info/DName/Input").get_text(),
			"version": ""
		},
		"nodes": {}
	}
	
	var nodes = save_data["nodes"]

	# save all nodes
	for node in get_node("./").get_children():
		if not node is BaseGraphNode:
			continue
		
		nodes[node.name] = node.serialize()
		
	# add connections to nodes
	for conn in get_connection_list():
		var from = { "name": conn["from"], "port": conn["from_port"] }
		var to = { "name": conn["to"], "port": conn["to_port"] }

		var node_to_input = nodes[to["name"]]["connections"]["input"]
		var node_from_output = nodes[from["name"]]["connections"]["output"]

		print(conn["from"], " ", node_from_output)
		print(conn["to"], " ", node_to_input)

		node_to_input[to["port"]].append(from)
		node_from_output[from["port"]].append(to)
	
	return save_data


func node_has_connection(node):
	for conn in get_connection_list():
		if conn.from == node.name or conn.to == node.name:
			return true
	return false


func _save_whiskers(path):
	# write the file
	print('saving file to: ', path)
	var saveFile = File.new()
	saveFile.open(path, File.WRITE)
	saveFile.store_line(to_json(serialize()))
	saveFile.close()
	# clear our data node
	data = {}
	EditorSingleton.last_save = EditorSingleton.current_history
	EditorSingleton.update_tab_title(false)


#======> Open file
func _open_whiskers(path):
	print('opening file: ', path)
	var file = File.new()
	file.open(path, File.READ)
	var loadData = parse_json(file.get_as_text())
	#var nodeDataKeys = loadData.keys()
	# we should restore our `info` tab data!
	get_node("../../Info/Info/DName/Input").set_text(loadData['info']['display_name'])
	get_node("../../Info/Info/Name/Input").set_text(loadData['info']['name'])
	
	var nodes = loadData["nodes"]

	# we should load our GraphNodes!
	for node_name in nodes:
		var node_data = nodes[node_name]
		
		for name in EditorSingleton.node_names:
			if not name in node_name:
				continue

			var type = str(name)+'.tscn'
					
			load_node(type, node_name, node_data)
			break
	
	# connect node in- and outputs
	for node_name in nodes:
		var node = nodes[node_name]
		var output_slots = node["connections"]["output"]

		for slot in output_slots:
			var to_outputs = output_slots[slot]

			# add multi output
			for out in to_outputs:
				connect_node(node_name, int(slot), out["name"], out["port"])

	var startOffset = self.get_node('Start').offset
	var graphRect = self.rect_size
	var startRect = self.get_node('Start').rect_size
	var scrollTo = Vector2(startOffset.x - (graphRect.x / 2) + (startRect.x / 2), startOffset.y - (graphRect.y / 2) + (startRect.y / 2))
	
	self.set_scroll_ofs(scrollTo)
	self.set_scroll_ofs(scrollTo)
	EditorSingleton.has_graph = true
	


#=== NEW FILE handling
func _on_New_confirmed():
	clear_graph()

func clear_graph():
	if EditorSingleton.has_player_singleton:
		get_tree().root.get_node('PlayerSingleton').queue_free()
		EditorSingleton.has_player_singleton = false
		get_node("../../Info/Info/DocFunc/ScrollContainer/Container").reset()
		get_node("../../Info/Info/DocVars/ScrollContainer/Container").reset()
	
	
	get_node("../../Info/Nodes/Stats/PanelContainer/StatsCon/ONodes/Amount").set_text('0')
	get_node("../../Info/Nodes/Stats/PanelContainer/StatsCon/DNodes/Amount").set_text('0')
	EditorSingleton.last_save = 0
	EditorSingleton.update_tab_title(false)
	#get_node("../Demo/Dialogue").reset()
	#get_node("../Demo/Dialogue").data = {}
	EditorSingleton.has_graph = false
	data = {}
	#get_node("../Demo/Dialogue/Text").parse_bbcode("You haven't loaded anything yet! Press [b]Update Demo[/b] to load your current graph!")
	# we should restore our `info` tab data!
	get_node("../../Info/Info/DName/Input").set_text('')
	get_node("../../Info/Info/Name/Input").set_text('')
	# we should clear the GraphEdit of GraphNodes
	for child in self.get_children():
		if not("GraphEditFilter" in child.get_class()) and not ("Control" in child.get_class()):
			child.queue_free()
			

#==== IMPORT PLAYER SINGLETON
func _import_singleton(path):
	var file = File.new()
	var script = GDScript.new()
	var PlayerSingleton = Control.new()
	PlayerSingleton.set_name('PlayerSingleton')
	
	file.open(path, File.READ)
	var loadData = file.get_as_text()
	
	script.set_source_code(loadData)
	script.reload()
	PlayerSingleton.set_script(script)
	get_tree().root.add_child(PlayerSingleton)
	EditorSingleton.has_player_singleton = true

#====== DRAG HANDLING
# checks if we can recive the dropped data
func can_drop_data(pos, data):
	return true

# triggers on target drop
func drop_data(pos, data):
	var nodes = EditorSingleton.node_names
	var inNode = false
	var localMousePos = self.get_child(0).get_local_mouse_position()
	for i in range(0, nodes.size()):
		if nodes[i] in data:
			init_scene(nodes[i]+".tscn", localMousePos)
			inNode = true
		elif !inNode and i + 1 == nodes.size():
			var name = init_scene('Expression.tscn', localMousePos)
			get_node(name).get_node("Lines").get_child(0).set_text(data)
