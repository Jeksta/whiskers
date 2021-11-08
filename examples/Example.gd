extends Node


func _ready():
	var path = "res://examples/test.json"
	
	var dialogue = WhiskersDialogue.new(path)
	
	var text = dialogue.start()
	print(dialogue.next())
	print(dialogue.next())
