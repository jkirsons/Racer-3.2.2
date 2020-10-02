tool
extends Spatial
class_name PathClone

export var parent_path : NodePath
export var object_res : PackedScene #Resource

export(float, 0, 1) var start_pos
export var copies: int
export(float, 0, 1) var space_between : float

export var offset : Vector3
export var random_rotate : bool = false
export var align_to_path : bool = false
export var clamp_to_ground : bool
export var mirror_x : bool

var parent_curve : Curve3D

var settings = {}
var timer : float = 0.0

func get_settings() -> Dictionary:
	var sett = {
		start_pos: start_pos,
		copies: copies,
		space_between: space_between,
		align_to_path: align_to_path,
		offset: offset,
		random_rotate: random_rotate,
		clamp_to_ground: clamp_to_ground,
		mirror_x: mirror_x
	}
	return sett

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.editor_hint:
		var parent : Path = get_node(parent_path)
		parent_curve = parent.curve
		parent.connect("curve_changed", self, "_on_Path_curve_changed")
	
func _process(delta):
	if Engine.editor_hint:
		var set = get_settings()
		if set.hash() != settings.hash():
			settings = set
			update_curve()

		if timer > 0:
			timer -= delta
		if timer < 0:
			update_curve()
			timer = 0

func _on_Path_curve_changed():
	timer = 3.0
	
func update_curve():
	if !parent_curve:
		parent_curve = get_node(parent_path).curve

	# delete all children
	for child in get_children():
		if "__" in String(child.name):
			remove_child(child)
			child.queue_free()
	
	for i in range(0, copies):
		
		# position of instance
		var length = parent_curve.get_baked_length()
		var pos = (start_pos + space_between * i) * length 
		if pos > length:
			pos = pos - length
		elif pos < 0:
			pos = pos + length
		
		# position offset
		var forward = Vector3()
		if pos < (length - 0.001):
			forward = (parent_curve.interpolate_baked(pos) - parent_curve.interpolate_baked(pos + 0.001)).normalized()
		else:
			forward = (parent_curve.interpolate_baked(pos - 0.001) - parent_curve.interpolate_baked(pos)).normalized()
		var up = -parent_curve.interpolate_baked_up_vector(pos, true).bounce(Vector3.UP).normalized()
		var right = forward.cross(up)
		
		#var m = MeshInstance.new()
		var m = object_res.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
		m.set_name(name + "__" + str(i))
		#m.set_mesh(object_res)
		add_child(m)
		m.set_owner(get_tree().get_edited_scene_root()) 
		
		if align_to_path:
			m.global_transform.basis = Basis(right, up, forward).orthonormalized()
		if random_rotate:
			m.transform = m.transform.rotated(Vector3(0.0, 1.0, 0.0), 2.0 * PI * randf())
		m.transform.origin = parent_curve.interpolate_baked(pos) + right * offset.x + up * offset.y + forward * offset.z
		
		if mirror_x:
			var m2 = object_res.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
			m2.set_name(String(name) + "__" + str(i) + "_(Mirror)")
			if align_to_path:
				m2.transform.basis = Basis(right, up, forward).orthonormalized()
			if random_rotate:
				m2.transform = m2.transform.rotated(Vector3(0.0, 1.0, 0.0), 2.0 * PI * randf())
			m2.transform.origin = parent_curve.interpolate_baked(pos) - right * offset.x + up * offset.y + forward * offset.z

			add_child(m2)
			m2.set_owner(get_tree().get_edited_scene_root())
		
		#print("add child " + str(i))
	
