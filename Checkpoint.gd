extends Area

export var index : int = -1

func _ready():
	connect("body_entered", self, "_on_Area_body_entered")

func _on_Area_body_entered(body):
	if body.name == "Vehicle":
		var lap_manager = body.get_node("Lap Manager")
		if index == lap_manager.first_checkpoint():
			lap_manager.check_lap()
		lap_manager.set_checkpoint(index)
