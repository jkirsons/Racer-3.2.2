extends Spatial

export var timer : float = 3
onready var timer_value : float = timer
export var timer_offset_max : float = 1
var timer_offset: float = 0

export var offset_max : Vector3 = Vector3(1,1,1)
var offset_position : Vector3


func _ready():
	pass

func _process(delta):
	var node = self
	if timer_value > 0:
		timer_value -= delta
	else:
		offset_position = Vector3((randf()*2-1) * offset_max.x, (randf()*2-1) * offset_max.y, (randf()*2-1) * offset_max.z)
		timer_offset = randf() * timer_offset_max * (1 if randf() > 0.5 else -1)
		var dist = (node.translation - offset_position).length()
		timer_value = max(dist / offset_max.length(), 0.3) * timer

		var tween = get_node("Tween")
		tween.interpolate_property(node, "translation",
				node.translation, offset_position, timer_value ,
				Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		tween.start()
	
	var up = node.translation.direction_to(Vector3.UP * 3)
	#node.transform.basis = node.transform.basis + Basis(up.cross(Vector3.BACK), up, Vector3.BACK).orthonormalized()

