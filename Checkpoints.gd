tool
extends Node
export var parent_node : NodePath
export var object_res : PackedScene
export(Array, int) var skip_indexes : Array

onready var parent_curve : Curve3D = get_node(parent_node).curve

var timer : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	var parent : Path = get_node(parent_node)
	parent.connect("curve_changed", self, "_on_Path_curve_changed")
	update_curve()

func _process(delta):
	if Engine.editor_hint:
		if timer > 0:
			timer -= delta
		if timer < 0:
			update_curve()
			timer = 0

func _on_Path_curve_changed():
	timer = 3.0

func update_curve():
	#print("updating checkpoints")
	# delete all children
	for child in get_children():
		if "__" in String(child.name):
			remove_child(child)
			child.queue_free()

	for i in range(0, parent_curve.get_point_count()):
		if i in skip_indexes:
			continue
		
		# position offset
		var forward : Vector3
		if i == 0:
			forward = (parent_curve.interpolate(i, 0.0) - parent_curve.interpolate(i, 0.01)).normalized()
		else:
			forward = (parent_curve.interpolate(i-1, 0.99) - parent_curve.interpolate(i, 0.0)).normalized()
		
		var up = Basis(forward, parent_curve.get_point_tilt(i)).y
		var right = forward.cross(up)
		
		var m = object_res.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
		m.set_name(name + "__" + str(i))
		m.index = i
		add_child(m)
		m.set_owner(get_tree().get_edited_scene_root()) 

		m.global_transform.basis = Basis(right, up, forward).orthonormalized()
		m.transform.origin = parent_curve.interpolate(i, 0.0)
