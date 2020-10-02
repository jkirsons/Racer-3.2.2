extends Node

onready var vehicle := find_parent('Vehicle')
onready var track_path : Path = get_node("/root/Root/Track/MainPath")
onready var checkpoint_script := get_node("/root/Root/Track/MainPath/Checkpoints")

var checkpoints : Array 
var total_checkpoints : int = 0
var lap = 1

signal progress_changed(value)

# Called when the node enters the scene tree for the first time.
func _ready():
	total_checkpoints = track_path.curve.get_point_count()
	checkpoints.resize(total_checkpoints)

func set_checkpoint(index):
	if index > 0:
		# find last checkpoint
		var last := -1
		for i in range(index-1, -1, -1):
			if not i in checkpoint_script.skip_indexes:
				last = i
				break
		# is the last checkpoint passed?
		if checkpoints[last] == 1:
			checkpoints[index] = 1
			emit_signal("progress_changed", float(index)/total_checkpoints * 100)
			return true
	else:
		# always set the 1st checkpoint
		checkpoints[index] = 1
		emit_signal("progress_changed", 0)
		return true
		
	# last checkpoint not passed
	print("Checkpoint not in sequence " + str(index))
	return false

func check_lap():
	# see if all checkpoints are passed
	var next_checkpoint = -1
	for i in range(0, total_checkpoints):
		if checkpoints[i] != 1 and not i in checkpoint_script.skip_indexes:
			next_checkpoint = i
			break
	
	# next lap
	if next_checkpoint == -1:
		clear_checkpoints()
		lap += 1
		print("Lap " + str(lap))
	
	#if checkpoints[first_checkpoint()] != 1 and checkpoints[last_checkpoint()] == 1:
	#	clear_checkpoints()

func first_checkpoint():
	for i in range(0, total_checkpoints-1):
		if not i in checkpoint_script.skip_indexes:
			return i

func last_checkpoint():
	for i in range(total_checkpoints-1, -1, -1):
		if not i in checkpoint_script.skip_indexes:
			return i

func clear_checkpoints():
	for i in range(0, total_checkpoints):
		checkpoints[i] = 0
