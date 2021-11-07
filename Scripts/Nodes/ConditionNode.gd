extends BaseGraphNode


func _ready():
	._ready()


func serialize():
	return ._serialize("condition")

