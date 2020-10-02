extends MarginContainer

onready var progress_bar := $ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func _on_Lap_Manager_progress_changed(value : float):
	progress_bar.value = value
