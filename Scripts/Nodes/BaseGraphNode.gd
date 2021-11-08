class_name BaseGraphNode extends GraphNode


func _ready():
	self.connect("close_request", self, "_on_Node_close_request")
	self.connect("resize_request", self, "_on_Node_resize_request")
	self.connect("dragged", self, "_on_Node_dragged")
	self.connect("raise_request", self, "_on_Node_raise_request")


func _on_Node_close_request():
	self.queue_free()
	print('removing node ' + name)
	EditorSingleton.update_stats(self.name, '-1')
	EditorSingleton.add_history(get_type(self.name), self.name, self.get_offset(), get_text(), get_node('../').get_connections(self.name), 'remove')


func _on_Node_resize_request(new_minsize):
	self.rect_size = new_minsize


func _on_Node_dragged(from, to):
	get_node('../').lastNodePosition = to
	EditorSingleton.add_history(get_type(self.name), self.name, to, get_text(), get_node('../').get_connections(self.name), 'move')


func _on_Node_resized():
	get_node("Lines").rect_min_size.y = self.get_rect().size.y - 45


func _on_Node_text_changed():
	pass


func _on_Node_line_changed(text):
	var length = text.length()
	if length > 0 and text[length - 1] == ' ':
		EditorSingleton.add_history(get_type(self.name), self.name, self.get_offset(), text, get_node('../').get_connections(self.name), 'text')


func _on_Node_raise_request():
	self.raise()


func _serialize(type):
	var data = {
		"type": type,
		"text": get_text(),
		"node_data": get_node_data(),
		
		"editor_data": {
			"location": get_offset(),
			"size": get_rect(),
		},
		"connections": {
			"input" : {},
			"output": {}
		}
	}

	var slot_count = get_child_count()
	var connections = data["connections"]

	for slot in range(slot_count):
		if is_slot_enabled_left(slot):
			connections["input"][slot] = []
		
		if is_slot_enabled_right(slot):
			connections["output"][slot] = []

	return data


func serialize():
	return ._serialize("base")


func set_node_data(data):
	pass


func get_node_data():
	return {
		"type": "none",
		"data": {},
	}


func get_type(name):
	for node_name in EditorSingleton.node_names:
		if node_name == name:
			return name


func set_text(val):
	if self.has_node('Lines'):
		var text = get_node("Lines").get_child(0)
		if text is LineEdit or text is TextEdit:
			text.set_text(val)


func get_text():
	if self.has_node('Lines'):
		var text = get_node("Lines").get_child(0)
		if text is LineEdit or text is TextEdit:
			return text.get_text()

	return ''

