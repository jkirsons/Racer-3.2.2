extends MeshInstance

onready var vehicle : Spatial = get_node('../Vehicle') as Spatial

func _process(_delta):
	transform.origin.x =  vehicle.global_transform.origin.x
	transform.origin.z = vehicle.global_transform.origin.z
